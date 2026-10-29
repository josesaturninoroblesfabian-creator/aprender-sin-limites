"""Audit Numbers missions, valid number ranges, patterns and packaged narration."""
import hashlib
import json
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[1]


def audit_numbers_activities():
    errors = []
    try:
        data = json.loads((ROOT / "data/numbers/activities.json").read_text(encoding="utf-8"))
        topics = ["one_digit", "two_digits", "three_digits", "four_digits"]
        expected = {f"{topic}_{tier}" for topic in topics for tier in range(1, 6)}
        if len(data["lessons"]) != 20 or {lesson["id"] for lesson in data["lessons"]} != expected:
            errors.append("Numbers must contain 20 distinct compatible mission IDs.")
        ids, referenced = set(), set()
        for lesson in data["lessons"]:
            width = lesson["width"]
            low, high = (0 if width == 1 else 10 ** (width - 1)), 10 ** width - 1
            if lesson["topic"] != topics[width - 1] or not low <= lesson["model_number"] <= high or len(lesson["questions"]) != 5:
                errors.append(f"Invalid Numbers mission: {lesson['id']}")
            for q in [lesson["model"], *lesson["questions"]]:
                if q["width"] != width or not low <= q["number"] <= high or not q["text"]:
                    errors.append(f"Invalid Numbers question range: {q['id']}")
                n = q["number"]
                kind = q["kind"]
                result = n
                if kind == "place":
                    if not 0 <= q["place"] < width: errors.append(f"Invalid place: {q['id']}")
                    result = n // 10 ** q["place"] % 10 * 10 ** q["place"]
                elif kind == "neighbor":
                    result = n + q["offset"]
                    if q["offset"] not in [-1, 1] or not low <= result <= high: errors.append(f"Neighbor escaped its number range: {q['id']}")
                elif kind == "order":
                    result = sorted(q["values"])
                    if len(set(result)) != 3 or any(not low <= item <= high for item in result): errors.append(f"Invalid order task: {q['id']}")
                elif kind not in ["build", "read", "compose"]:
                    errors.append(f"Unknown Numbers question kind: {kind}")
                if result != q["result"]: errors.append(f"Wrong Numbers answer: {q['id']}")
                if q["id"] in ids: errors.append(f"Duplicate Numbers question: {q['id']}")
                ids.add(q["id"])
                referenced.add(q["audio"].split("/")[-1].removesuffix(".mp3"))
        for key in ["sequences", "comparisons"]:
            if len(data[key]) != 32: errors.append(f"Expected 32 Numbers {key}.")
            for width in range(1, 5):
                if sum(q["width"] == width for q in data[key]) != 8: errors.append(f"Incomplete {width}-digit {key}.")
            for q in data[key]:
                low, high = (0 if q["width"] == 1 else 10 ** (q["width"] - 1)), 10 ** q["width"] - 1
                if key == "sequences":
                    terms = q["terms"]
                    if len(terms) != 5 or not q["step"] or not 0 <= q["missing"] < 5 or any(not low <= term <= high for term in terms):
                        errors.append(f"Invalid sequence: {q['id']}")
                    if any(b - a != q["step"] for a, b in zip(terms, terms[1:])) or q["result"] != terms[q["missing"]]: errors.append(f"Wrong sequence: {q['id']}")
                else:
                    left, right = q["left"], q["right"]
                    if not all(low <= term <= high for term in [left, right]) or q["result"] != (">" if left > right else "<" if left < right else "="):
                        errors.append(f"Wrong comparison: {q['id']}")
                if q["id"] in ids: errors.append(f"Duplicate Numbers question: {q['id']}")
                ids.add(q["id"])
                referenced.add(q["audio"].split("/")[-1].removesuffix(".mp3"))
        totals = data["market_totals"]
        if len(totals) != 8 or totals[0] != 0 or any(not isinstance(n, int) or not 0 <= n <= 40 for n in totals): errors.append("Invalid Numbers market rounds.")
        catalog = json.loads((ROOT / "data/numbers/voice_lines.json").read_text(encoding="utf-8"))["clips"]
        provenance = json.loads((ROOT / "data/numbers/voice_provenance.json").read_text(encoding="utf-8"))
        if len(catalog) != 228 or set(catalog) != set(provenance["clips"]) or not referenced.issubset(catalog) or provenance["voice"] != "es-PE-CamilaNeural":
            errors.append("Incomplete Numbers narration or inconsistent llama voice.")
        for key, entry in catalog.items():
            audio = (ROOT / "assets/audio/llama/numbers_activities" / entry["file"]).read_bytes()
            record = provenance["clips"][key]
            if len(audio) < 1000 or record["sha256"] != hashlib.sha256(audio).hexdigest() or record["text_sha256"] != hashlib.sha256(entry["text"].encode("utf-8")).hexdigest(): errors.append(f"Numbers narration mismatch: {key}")
        for name, ratio in [("scenery", 16 / 9), ("props", 2)]:
            raw = (ROOT / f"assets/ui/numbers/activities/{name}-atlas.png").read_bytes()
            w, h = struct.unpack(">II", raw[16:24])
            if not raw.startswith(b"\x89PNG") or w < 1500 or abs(w / h - ratio) > .03: errors.append(f"Invalid Numbers art: {name}")
    except (OSError, ValueError, KeyError, TypeError, IndexError, ZeroDivisionError, struct.error) as error:
        errors.append(f"Could not audit Numbers: {error}")
    return errors


if __name__ == "__main__":
    problems = audit_numbers_activities()
    print("\n".join(problems) if problems else "OK: 20 Numbers missions, 100 challenges, 32 sequences, 32 comparisons, 8 market rounds and 228 local voice clips.")
    raise SystemExit(1 if problems else 0)
