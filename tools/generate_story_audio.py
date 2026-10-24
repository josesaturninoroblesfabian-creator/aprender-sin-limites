"""Generate Carmelo's packaged male narration and word timings; not used at runtime."""
from __future__ import annotations

import argparse
import asyncio
from datetime import datetime, timezone
import hashlib
import html
import importlib.metadata
import json
from pathlib import Path
import re

import edge_tts

ROOT = Path(__file__).resolve().parents[1]


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


async def run(args: argparse.Namespace) -> None:
    voices = await edge_tts.list_voices()
    voice = next((item for item in voices if item["ShortName"] == args.voice and item["Gender"] == "Male"), None)
    if voice is None:
        raise ValueError("An available male voice is required for Carmelo")
    library = json.loads((ROOT / "assets/data/cuentos.json").read_text(encoding="utf-8"))["stories"]
    lines = json.loads((ROOT / "data/stories/carmelo_lines.json").read_text(encoding="utf-8"))
    jobs = {f"guide/{key}": text for key, text in lines.items()}
    for story in library:
        for index, page in enumerate(story["pages"]):
            jobs[f"{story['id']}/page_{index:02d}"] = page["text"] + " " + page["speech"]
        for index, question in enumerate(story["questions"]):
            text = question["prompt"] + " " + " ".join(f"{number + 1}. {choice}." for number, choice in enumerate(question["choices"]))
            jobs[f"{story['id']}/question_{index:02d}"] = text
    if args.stories:
        jobs = {key: text for key, text in jobs.items() if key.split("/")[0] in args.stories or key.startswith("guide/")}
    manifest_path = ROOT / "data/stories/audio_manifest.json"
    previous = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {}
    records = previous.get("clips", {}).copy()
    semaphore = asyncio.Semaphore(3)

    async def render(clip_id: str, text: str) -> None:
        if not re.fullmatch(r"[a-z_]+/[a-z_]+(?:_\d{2})?", clip_id):
            raise ValueError(clip_id)
        path = ROOT / "assets/audio/stories" / (clip_id + ".mp3")
        timings_path = path.with_suffix(".timing.json")
        old = records.get(clip_id, {})
        if not args.overwrite and previous.get("voice") == args.voice and previous.get("rate") == args.rate and path.exists() and timings_path.exists() and old.get("text_sha256") == sha(text.encode("utf-8")) and old.get("sha256") == sha(path.read_bytes()) and old.get("timing_sha256") == sha(timings_path.read_bytes()):
            return
        async with semaphore:
            path.parent.mkdir(parents=True, exist_ok=True)
            audio_temp = path.with_suffix(".mp3.tmp")
            raw_temp = path.with_suffix(".metadata.tmp")
            for attempt in range(3):
                try:
                    await edge_tts.Communicate(text, args.voice, rate=args.rate, boundary="WordBoundary").save(str(audio_temp), str(raw_temp))
                    if audio_temp.stat().st_size < 1000:
                        raise ValueError("Empty narration")
                    break
                except Exception:
                    if attempt == 2:
                        raise
                    await asyncio.sleep(1 + attempt)
            words = []
            cursor = 0
            for line in raw_temp.read_text(encoding="utf-8").splitlines():
                item = json.loads(line)
                word = html.unescape(item["text"])
                start = text.find(word, cursor)
                if start < 0:
                    start = text.lower().find(word.lower(), cursor)
                if start >= 0:
                    words.append({"start": item["offset"] / 10_000_000, "end": (item["offset"] + item["duration"]) / 10_000_000, "from": start, "to": start + len(word)})
                    cursor = start + len(word)
            audio_temp.replace(path)
            timings_path.write_text(json.dumps({"text": text, "words": words}, ensure_ascii=False) + "\n", encoding="utf-8")
            raw_temp.unlink()
            records[clip_id] = {"text_sha256": sha(text.encode("utf-8")), "sha256": sha(path.read_bytes()), "timing_sha256": sha(timings_path.read_bytes())}
            print(f"Ready {clip_id} ({len(words)} timed words)", flush=True)

    await asyncio.gather(*(render(key, text) for key, text in jobs.items()))
    manifest_path.write_text(json.dumps({"voice": args.voice, "gender": voice["Gender"], "locale": voice["Locale"], "rate": args.rate, "tool": "edge-tts", "tool_version": importlib.metadata.version("edge-tts"), "generated_at": datetime.now(timezone.utc).isoformat(), "runtime": "Packaged offline playback, no online generation during play", "clips": dict(sorted(records.items()))}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Narration manifest: {len(records)} clips", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--voice", default="es-PE-AlexNeural")
    parser.add_argument("--rate", default="-8%")
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--stories", nargs="*")
    asyncio.run(run(parser.parse_args()))
