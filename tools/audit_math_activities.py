"""Audit the mathematics curriculum, illustrations and packaged narration."""
import hashlib
import json
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]


def audit_math_activities():
    errors = []
    try:
        lessons = json.loads((ROOT / "data/math/activities.json").read_text(encoding="utf-8"))["lessons"]
        expected_ids = {f"{operation}_{tier}" for operation in ("addition", "subtraction", "multiplication", "division") for tier in range(1, 5)}
        if {lesson["id"] for lesson in lessons} != expected_ids or len(lessons) != 16:
            errors.append("Mathematics must preserve 16 distinct mission identifiers.")
        clip_ids = set()
        question_ids = set()
        for lesson in lessons:
            if len(lesson["questions"]) != 6 or not lesson["aim"] or not lesson["title"]:
                errors.append(f"Incomplete mathematics mission: {lesson['id']}")
            for item in [lesson["model"], *lesson["questions"]]:
                a, b, operation = item["a"], item["b"], item["operation"]
                if not isinstance(a, int) or not isinstance(b, int) or min(a, b) < 0 or operation != lesson["topic"]:
                    errors.append(f"Invalid mathematics operands: {item['id']}")
                    continue
                if operation == "division" and (b <= 0 or a % b):
                    errors.append(f"Non-exact or zero-divisor division: {item['id']}")
                    continue
                correct = {"addition": lambda: a + b, "subtraction": lambda: a - b,
                           "multiplication": lambda: a * b, "division": lambda: a // b}[operation]()
                if correct != item["result"] or correct < 0 or not item["text"]:
                    errors.append(f"Wrong mathematics answer: {item['id']}")
                clip_ids.add(item["audio"].removeprefix("res://assets/audio/llama/activities/").removesuffix(".mp3"))
                if item["id"] in question_ids:
                    errors.append(f"Duplicate mathematics question ID: {item['id']}")
                question_ids.add(item["id"])
        voice = json.loads((ROOT / "data/math/activities_voice_lines.json").read_text(encoding="utf-8"))["clips"]
        manifest = json.loads((ROOT / "data/math/activities_voice_provenance.json").read_text(encoding="utf-8"))
        if manifest["voice"] != "es-PE-CamilaNeural" or set(manifest["clips"]) != set(voice) or len(voice) != 155 or not clip_ids.issubset(voice):
            errors.append("Incomplete mathematics voice pack or changed llama voice.")
        for key, line in voice.items():
            audio = (ROOT / "assets/audio/llama/activities" / line["file"]).read_bytes()
            record = manifest["clips"][key]
            if len(audio) < 1000 or record["sha256"] != hashlib.sha256(audio).hexdigest() or record["text_sha256"] != hashlib.sha256(line["text"].encode("utf-8")).hexdigest():
                errors.append(f"Mathematics narration mismatch: {key}")
        for asset, ratio in [("assets/ui/math/activities/scenery-atlas.png", 16 / 9),
                             ("assets/ui/math/activities/objects-atlas.png", 2),
                             ("assets/characters/llama/adventure/run-atlas.png", 2)]:
            data = (ROOT / asset).read_bytes()
            width, height = struct.unpack(">II", data[16:24])
            if not data.startswith(b"\x89PNG") or width < 1500 or abs(width / height - ratio) > .06:
                errors.append(f"Invalid mathematics atlas: {asset}")
    except (OSError, ValueError, KeyError, TypeError, ZeroDivisionError, struct.error) as error:
        errors.append(f"Could not audit mathematics activities: {error}")
    return errors


if __name__ == "__main__":
    problems = audit_math_activities()
    print("\n".join(problems) if problems else "OK: 8 mathematics destinations, 16 missions, 96 questions, 12 paths and 155 local voice clips.")
    raise SystemExit(1 if problems else 0)
