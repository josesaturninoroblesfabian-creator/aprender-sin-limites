"""Build packaged neural narration; network is needed only by this development tool."""
from __future__ import annotations

import argparse
import asyncio
from datetime import datetime, timezone
import hashlib
import importlib.metadata
import json
from pathlib import Path
import re

import edge_tts

ROOT = Path(__file__).resolve().parents[1]
SECTIONS = ("numbers", "mathematics", "geometry")


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


async def generate(args: argparse.Namespace) -> None:
    semaphore = asyncio.Semaphore(2)
    voice_list = await edge_tts.list_voices()
    selected = next((voice for voice in voice_list if voice["ShortName"] == args.voice), None)
    if selected is None:
        raise ValueError(f"Voice not available: {args.voice}")

    for section in args.sections:
        catalog_path = ROOT / f"data/math/{section}_voice_lines.json"
        catalog = json.loads(catalog_path.read_text(encoding="utf-8"))["clips"]
        folder = ROOT / "assets/audio/llama" / section
        folder.mkdir(parents=True, exist_ok=True)
        manifest_path = ROOT / f"data/math/{section}_voice_provenance.json"
        previous = json.loads(manifest_path.read_text(encoding="utf-8-sig")) if manifest_path.exists() else {}
        records = {}

        async def render(clip_id: str, entry: dict) -> None:
            filename = entry["file"]
            if not re.fullmatch(r"[a-z_]+\.mp3", filename):
                raise ValueError(f"Invalid filename: {filename}")
            path = folder / filename
            text_hash = digest(entry["text"].encode("utf-8"))
            old = previous.get("clips", {}).get(clip_id, {})
            if not args.overwrite and path.exists() and previous.get("voice") == args.voice and previous.get("rate") == args.rate and old.get("text_sha256") == text_hash and old.get("sha256") == digest(path.read_bytes()):
                records[clip_id] = old
                return
            async with semaphore:
                temporary = path.with_suffix(".mp3.tmp")
                for attempt in range(3):
                    try:
                        await edge_tts.Communicate(entry["text"], args.voice, rate=args.rate).save(str(temporary))
                        if temporary.stat().st_size < 1000:
                            raise ValueError("Narration is empty or truncated")
                        temporary.replace(path)
                        break
                    except Exception:
                        if attempt == 2:
                            raise
                        await asyncio.sleep(1 + attempt)
                records[clip_id] = {"file": filename, "text_sha256": text_hash, "sha256": digest(path.read_bytes())}
                print(f"Generated {section}/{filename}", flush=True)

        await asyncio.gather(*(render(clip_id, entry) for clip_id, entry in catalog.items()))
        manifest = {
            "provider": "Microsoft Edge online neural text-to-speech",
            "tool": "edge-tts", "tool_version": importlib.metadata.version("edge-tts"),
            "voice": args.voice, "locale": selected["Locale"], "gender": selected["Gender"],
            "rate": args.rate, "pitch": "+0Hz", "generated_at": datetime.now(timezone.utc).isoformat(),
            "generation": "Synthesized online during development; packaged MP3 playback is fully offline",
            "catalog": catalog_path.relative_to(ROOT).as_posix(),
            "clips": dict(sorted(records.items())),
            "documentation": "https://github.com/rany2/edge-tts",
        }
        manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"Ready: {section} ({len(records)} clips)", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--voice", default="es-PE-CamilaNeural")
    parser.add_argument("--rate", default="-5%")
    parser.add_argument("--sections", nargs="+", choices=SECTIONS, default=SECTIONS)
    parser.add_argument("--overwrite", action="store_true")
    asyncio.run(generate(parser.parse_args()))
