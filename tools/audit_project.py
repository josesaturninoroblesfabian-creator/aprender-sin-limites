"""Check local Godot resources and language content using only Python's stdlib."""

from __future__ import annotations

import json
import hashlib
from pathlib import Path
import re
import sys
import wave


ROOT = Path(__file__).resolve().parents[1]
LETTERS = list("ABCDEFGHIJKLMNÑOPQRSTUVWXYZ")
TEXT_SUFFIXES = {".gd", ".tscn", ".tres", ".godot", ".import"}


def active_files():
    for folder in (ROOT / "assets", ROOT / "data", ROOT / "scripts", ROOT / "scenes"):
        yield from (p for p in folder.rglob("*") if p.is_file())
    yield ROOT / "project.godot"


def audit() -> list[str]:
    errors: list[str] = []
    files = list(active_files())
    # Compare exact spelling as exported Godot packs are case-sensitive.
    exact_paths = {p.relative_to(ROOT).as_posix() for p in files}
    for path in files:
        relative = path.relative_to(ROOT).as_posix()
        if path.suffix == ".import" and not Path(str(path)[:-7]).is_file():
            errors.append(f"Orphan import: {relative}")
        if path.suffix == ".gd" and not Path(str(path) + ".uid").is_file():
            errors.append(f"Missing script UID: {relative}")
        if path.suffix not in TEXT_SUFFIXES:
            continue
        text = path.read_text(encoding="utf-8-sig")
        for resource in re.findall(r'"res://([^"\n]+)"', text):
            if resource.startswith(".godot/"):
                continue  # Generated import output, rebuilt on each computer.
            if resource.endswith("/") and (ROOT / resource).is_dir():
                continue  # A directory prefix joined to a validated catalog filename.
            if "%" in resource:
                if "%03d" in resource or "%02d" in resource:
                    parent = ROOT / Path(resource).parent
                    if not parent.is_dir() or not list(parent.glob("*.png")):
                        errors.append(f"Missing animation folder: {relative} -> {resource}")
                elif "%s" in resource:
                    for letter in LETTERS:
                        if resource % letter not in exact_paths:
                            errors.append(f"Missing letter resource: {resource % letter}")
                else:
                    errors.append(f"Unchecked resource template: {relative} -> {resource}")
                continue  # Exact sequence lengths are checked below.
            if resource not in exact_paths:
                errors.append(f"Missing resource: {relative} -> {resource}")
    for relative, count in {
        "assets/characters/nina/welcome": 100,
        "assets/characters/nino/welcome": 107,
        "assets/characters/nina/goodbye": 78,
        "assets/characters/condor/frames": 119,
    }.items():
        expected = {f"frame_{index:03d}.png" for index in range(count)}
        found = {p.name for p in (ROOT / relative).glob("*.png")}
        if found != expected:
            errors.append(f"Incomplete frame sequence: {relative}")
    for letter in LETTERS:
        if not (ROOT / "assets/ui/tracing/letters" / f"{letter}.png").is_file():
            errors.append(f"Missing tracing image: {letter}")
    for index in range(1, 7):
        if not (ROOT / f"assets/characters/nina/nina-habla-{index:02d}.png").is_file():
            errors.append(f"Missing talking frame: {index}")
    try:
        data = json.loads((ROOT / "data/language/abecedario.json").read_text(encoding="utf-8"))
        if not isinstance(data, dict) or list(data) != LETTERS:
            errors.append("The alphabet must contain 27 letters in Spanish order.")
        else:
            for letter, words in data.items():
                if not isinstance(words, list) or len(words) != 10:
                    errors.append(f"{letter}: expected 10 examples.")
                    continue
                for word in words:
                    if not isinstance(word, str) or "|" not in word or not all(word.split("|", 1)):
                        errors.append(f"{letter}: invalid word|picture example: {word!r}")
    except (OSError, ValueError) as error:
        errors.append(f"Could not read alphabet data: {error}")
    try:
        clips = json.loads((ROOT / "data/audio/voice_lines.json").read_text(encoding="utf-8"))["clips"]
        if len(clips) != 300:
            errors.append("Expected 300 local narration clips.")
        for clip_id, entry in clips.items():
            relative = entry["path"].removeprefix("res://")
            if relative not in exact_paths:
                errors.append(f"Missing voice clip: {clip_id} -> {relative}")
                continue
            with wave.open(str(ROOT / relative), "rb") as audio:
                if audio.getnframes() == 0:
                    errors.append(f"Empty voice clip: {clip_id}")
        for letter_index, letter in enumerate(LETTERS):
            for example_index, example in enumerate(data.get(letter, [])):
                clip_id = f"word_{letter_index:02d}_{example_index:02d}"
                if clips.get(clip_id, {}).get("text") != example.split("|", 1)[0]:
                    errors.append(f"Voice catalog no longer matches the word: {clip_id}")
    except (OSError, ValueError, KeyError, wave.Error) as error:
        errors.append(f"Could not validate voice pack: {error}")
    shared_voices = set()
    topic_ids = {
        "numbers": {"one_digit", "two_digits", "three_digits", "four_digits", "count_objects", "sequences", "compare", "quick_challenge"},
        "mathematics": {"addition", "subtraction", "multiplication", "division", "count_objects", "solve_exercises", "level_game", "quick_challenge"},
        "geometry": {"flat_shapes", "solid_shapes", "sides_vertices", "shape_patterns", "find_shape", "build_pattern", "count_sides", "quick_challenge"},
    }
    for section, topics in topic_ids.items():
        try:
            narration = json.loads((ROOT / f"data/math/{section}_voice_lines.json").read_text(encoding="utf-8"))["clips"]
            provenance = json.loads((ROOT / f"data/math/{section}_voice_provenance.json").read_text(encoding="utf-8-sig"))
            shared_voices.add(provenance["voice"])
            if set(narration) != topics | {"welcome", "help", "progress"}:
                errors.append(f"Incomplete {section} narration catalog.")
            for clip_id, entry in narration.items():
                filename = entry["file"]
                if not re.fullmatch(r"[a-z_]+\.mp3", filename):
                    errors.append(f"Invalid {section} voice filename: {clip_id}")
                    continue
                audio = (ROOT / "assets/audio/llama" / section / filename).read_bytes()
                if len(audio) < 1000 or not (audio.startswith(b"ID3") or (audio[0] == 0xff and audio[1] & 0xe0 == 0xe0)):
                    errors.append(f"Invalid or empty MP3: {section}/{clip_id}")
                record = provenance["clips"][clip_id]
                if record["sha256"] != hashlib.sha256(audio).hexdigest() or record["text_sha256"] != hashlib.sha256(entry["text"].encode("utf-8")).hexdigest():
                    errors.append(f"Narration no longer matches its generated text/audio: {section}/{clip_id}")
        except (OSError, ValueError, KeyError) as error:
            errors.append(f"Could not validate {section} narration: {error}")
    if len(shared_voices) != 1:
        errors.append("The three llama sections must share one voice.")
    return errors


if __name__ == "__main__":
    problems = audit()
    if problems:
        print("\n".join(problems))
        sys.exit(1)
    print("OK: resource paths, script UIDs, 404 animation frames, 27 tracing images, 270 examples, 300 Language clips and 33 neural llama clips.")
