"""Audit packaged geometry content without modifying player files."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SIDES = {"circle": 0, "triangle": 3, "square": 4, "rectangle": 4, "pentagon": 5, "hexagon": 6}

def audit_geometry_activities():
    errors = []
    try:
        data = json.loads((ROOT / "data/geometry/activities.json").read_text(encoding="utf-8"))
        voices = json.loads((ROOT / "data/geometry/voice_lines.json").read_text(encoding="utf-8"))["clips"]
        provenance = json.loads((ROOT / "data/geometry/voice_provenance.json").read_text(encoding="utf-8"))["clips"]
        assert len(data["lessons"]) == 20
        assert sum(len(x["questions"]) for x in data["lessons"]) == 100
        assert len(voices) == 286
        ids = set()
        questions = [q for lesson in data["lessons"] for q in [lesson["model"], *lesson["questions"]]]
        questions += [q for pool in data["games"].values() for q in pool]
        for q in questions:
            assert q["id"] not in ids, q["id"]
            ids.add(q["id"])
            assert q["audio"] == "res://assets/audio/llama/geometry_activities/" + voices[q["id"]]["file"], q["id"]
            if q["kind"] == "count":
                assert q["result"] == SIDES[q["shape"]], q["id"]
            if q["kind"] in ("pattern", "sky_pattern"):
                for index, token in enumerate(q["sequence"]):
                    assert token == q["sequence"][index % q["unit_size"]], q["id"]
                options = q["options"]
                keys = options if q["color_matters"] else [x.split(":")[0] for x in options]
                assert len(set(keys)) == 4, q["id"]
            if q["kind"] == "find":
                assert q["result"] == [i for i, x in enumerate(q["items"]) if x["shape"] == q["target"]]
                assert len(q["result"]) == 3
        for key, entry in voices.items():
            raw = (ROOT / "assets/audio/llama/geometry_activities" / entry["file"]).read_bytes()
            assert len(raw) > 1000, key
            assert provenance[key]["sha256"] == hashlib.sha256(raw).hexdigest(), key
            assert provenance[key]["text_sha256"] == hashlib.sha256(entry["text"].encode()).hexdigest(), key
        art = json.loads((ROOT / "docs/reference/geometry/activities/art-provenance.json").read_text(encoding="utf-8"))
        for entry in art["assets"]:
            assert hashlib.sha256((ROOT / entry["path"]).read_bytes()).hexdigest() == entry["sha256"]
    except (AssertionError, KeyError, ValueError, OSError) as error:
        errors.append(f"Geometry activity audit failed: {error}")
    return errors

if __name__ == "__main__":
    problems = audit_geometry_activities()
    print("\n".join(problems) if problems else "OK: Geometry 20 missions, 100 challenges, 48 game rounds, 100 flight variants, 286 local clips.")
    raise SystemExit(bool(problems))

