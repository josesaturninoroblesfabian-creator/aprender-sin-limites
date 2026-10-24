"""Check story structure, atlas files, narration, word timings and source consistency."""
import hashlib
import json
from pathlib import Path
import struct
from story_audio_metadata import timing_matches

ROOT = Path(__file__).resolve().parents[1]


def audit_stories() -> list[str]:
    errors = []
    try:
        catalog = json.loads((ROOT / "assets/data/cuentos.json").read_text(encoding="utf-8"))["stories"]
        source = json.loads((ROOT / "data/stories/library.json").read_text(encoding="utf-8"))["stories"]
        original = json.loads((ROOT / "docs/reference/stories/original_catalog.json").read_text(encoding="utf-8"))["stories"]
        if len(catalog) != 16 or {s["id"] for s in catalog} != {s["id"] for s in original}:
            errors.append("All 16 original story IDs must be preserved.")
        source_by_id = {story["id"]: story for story in source}
        jobs = {"guide/" + key: text for key, text in json.loads((ROOT / "data/stories/carmelo_lines.json").read_text(encoding="utf-8")).items()}
        answers = set()
        for story in catalog:
            story_id = story["id"]
            if len(story["pages"]) != 8 or len(story["questions"]) != 4 or story["order"] != [0, 2, 5, 7]:
                errors.append(f"Incomplete story journey: {story_id}")
            if len({page["heading"] for page in story["pages"]}) != 8:
                errors.append(f"Repeated scene headings: {story_id}")
            atlas = ROOT / story["atlas"].removeprefix("res://")
            if not atlas.exists():
                errors.append(f"Missing eight-scene atlas: {story_id}")
            else:
                data = atlas.read_bytes()
                width, height = struct.unpack(">II", data[16:24])
                if not data.startswith(b"\x89PNG") or width < 1500 or abs(width / height - 2) > 0.03:
                    errors.append(f"Story atlas must have a 4x2 layout: {story_id}")
            for index, page in enumerate(story["pages"]):
                author = source_by_id[story_id]["pages"][index]
                if page["text"] != author["text"] or page["speech"] != author["speech"]:
                    errors.append(f"Rebuild the story catalog: {story_id}/{index}")
                if len(page["text"].split()) < 25 or not page["speech"]:
                    errors.append(f"Scene has insufficient narrative context: {story_id}/{index}")
                jobs[f"{story_id}/page_{index:02d}"] = page["text"] + " " + page["speech"]
            for index, question in enumerate(story["questions"]):
                choices = question["choices"]
                if len(set(choices)) != 3 or question["answer"] not in choices or not 0 <= question["evidence"] < 8 or not question["explanation"]:
                    errors.append(f"Invalid comprehension question: {story_id}/{index}")
                else:
                    answers.add(choices.index(question["answer"]))
                jobs[f"{story_id}/question_{index:02d}"] = question["prompt"] + " " + " ".join(f"{number + 1}. {choice}." for number, choice in enumerate(choices))
        if answers != {0, 1, 2}:
            errors.append("Vary the position of correct answers.")
        manifest = json.loads((ROOT / "data/stories/audio_manifest.json").read_text(encoding="utf-8"))
        if manifest["gender"] != "Male" or set(manifest["clips"]) != set(jobs):
            errors.append("Carmelo requires complete, documented male narration.")
        for clip_id, text in jobs.items():
            record = manifest["clips"][clip_id]
            path = ROOT / "assets/audio/stories" / (clip_id + ".mp3")
            audio = path.read_bytes()
            timing_bytes = path.with_suffix(".timing.json").read_bytes()
            timings = json.loads(timing_bytes)
            if len(audio) < 1000 or record["sha256"] != hashlib.sha256(audio).hexdigest() or record["text_sha256"] != hashlib.sha256(text.encode("utf-8")).hexdigest() or not timing_matches(timing_bytes, record["timing_sha256"]):
                errors.append(f"Narration differs from its current text or manifest: {clip_id}")
            if timings["text"] != text or len(timings["words"]) < 5:
                errors.append(f"Missing word synchronization: {clip_id}")
            previous_time = -1.0
            previous_character = 0
            for word in timings["words"]:
                if not (previous_time <= word["start"] < word["end"] and previous_character <= word["from"] < word["to"] <= len(text)):
                    errors.append(f"Invalid word timing: {clip_id}")
                    break
                previous_time = word["end"]
                previous_character = word["to"]
    except (OSError, ValueError, KeyError, struct.error, TypeError) as error:
        errors.append(f"Could not audit story library: {error}")
    return errors


if __name__ == "__main__":
    problems = audit_stories()
    print("\n".join(problems) if problems else "OK: 16 stories, 128 scenes, 64 questions and 205 male narration clips.")
    raise SystemExit(1 if problems else 0)
