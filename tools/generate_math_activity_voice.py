"""Prepare the llama's natural narration once; playback in the game is offline."""
import argparse
import asyncio
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re

import edge_tts

ROOT = Path(__file__).resolve().parents[1]


def sha(data):
    return hashlib.sha256(data).hexdigest()


async def run(overwrite=False):
    voice, rate = "es-PE-CamilaNeural", "-5%"
    catalog = json.loads((ROOT / "data/math/activities_voice_lines.json").read_text(encoding="utf-8"))["clips"]
    manifest_path = ROOT / "data/math/activities_voice_provenance.json"
    previous = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {}
    folder = ROOT / "assets/audio/llama/activities"
    folder.mkdir(parents=True, exist_ok=True)
    records = {}
    limit = asyncio.Semaphore(3)

    async def render(key, item):
        filename = item["file"]
        assert re.fullmatch(r"[a-z0-9_]+\.mp3", filename)
        path = folder / filename
        text_hash = sha(item["text"].encode("utf-8"))
        old = previous.get("clips", {}).get(key, {})
        if not overwrite and previous.get("voice") == voice and previous.get("rate") == rate and path.exists() and old.get("text_sha256") == text_hash and old.get("sha256") == sha(path.read_bytes()):
            records[key] = old
            return
        async with limit:
            temporary = path.with_suffix(".mp3.tmp")
            for attempt in range(3):
                try:
                    await edge_tts.Communicate(item["text"], voice, rate=rate).save(str(temporary))
                    assert temporary.stat().st_size > 1000
                    temporary.replace(path)
                    break
                except Exception:
                    if attempt == 2:
                        raise
                    await asyncio.sleep(1 + attempt)
            records[key] = {"file": filename, "text_sha256": text_hash, "sha256": sha(path.read_bytes())}
            print("Ready " + key, flush=True)

    await asyncio.gather(*(render(key, item) for key, item in catalog.items()))
    manifest_path.write_text(json.dumps({"voice": voice, "rate": rate, "gender": "Female", "locale": "es-PE",
        "generated_at": datetime.now(timezone.utc).isoformat(), "runtime": "Offline packaged MP3 playback",
        "tool": "edge-tts", "clips": dict(sorted(records.items()))}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"Complete: {len(records)} local voice clips.", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--overwrite", action="store_true")
    args = parser.parse_args()
    asyncio.run(run(args.overwrite))
