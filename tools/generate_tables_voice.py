"""Generate whole spoken equations once. Runtime playback is entirely offline."""
import argparse
import asyncio
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path

import edge_tts

ROOT = Path(__file__).resolve().parents[1]
VOICE, RATE = "es-PE-CamilaNeural", "-5%"


def sha(data):
    return hashlib.sha256(data).hexdigest()


async def run(jobs):
    lines = json.loads((ROOT / "data/math/tables_voice_lines.json").read_text(encoding="utf-8"))["clips"]
    manifest_path = ROOT / "data/math/tables_voice_provenance.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {}
    records = manifest.get("clips", {}) if manifest.get("voice") == VOICE and manifest.get("rate") == RATE else {}
    folder = ROOT / "assets/audio/llama/tables"
    folder.mkdir(parents=True, exist_ok=True)
    limit = asyncio.Semaphore(jobs)
    done = 0

    def save():
        data = dict(voice=VOICE, rate=RATE, gender="Female", locale="es-PE", tool="edge-tts",
                    runtime="Offline packaged MP3 playback; whole equations, not concatenated words",
                    generated_at=datetime.now(timezone.utc).isoformat(), clips=dict(sorted(records.items())))
        temporary = manifest_path.with_suffix(".json.tmp")
        temporary.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        temporary.replace(manifest_path)

    async def render(key, line):
        nonlocal done
        path = folder / line["file"]
        text_hash = sha(line["text"].encode("utf-8"))
        old = records.get(key, {})
        if path.exists() and old.get("text_sha256") == text_hash and old.get("sha256") == sha(path.read_bytes()):
            done += 1
            return
        async with limit:
            temporary = path.with_suffix(".mp3.tmp")
            for attempt in range(6):
                try:
                    await edge_tts.Communicate(line["text"], VOICE, rate=RATE).save(str(temporary))
                    if temporary.stat().st_size < 1000:
                        raise ValueError("Empty narration")
                    temporary.replace(path)
                    break
                except Exception:
                    if attempt == 5:
                        raise
                    await asyncio.sleep(2 ** attempt)
            records[key] = dict(file=line["file"], text_sha256=text_hash, sha256=sha(path.read_bytes()))
            done += 1
            save()  # Resumable even if a later request fails.
            if done % 15 == 0:
                print(f"Ready {done}/{len(lines)}", flush=True)

    await asyncio.gather(*(render(key, line) for key, line in lines.items()))
    save()
    print(f"Complete: {done} local whole-equation clips.", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--jobs", type=int, default=5)
    asyncio.run(run(parser.parse_args().jobs))
