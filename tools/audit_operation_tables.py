"""Verify all 900 equations and the matching whole-line offline narration."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def audit_operation_tables():
    errors = []
    try:
        tables = json.loads((ROOT / "data/math/operation_tables.json").read_text(encoding="utf-8"))["tables"]
        lines = json.loads((ROOT / "data/math/tables_voice_lines.json").read_text(encoding="utf-8"))["clips"]
        provenance = json.loads((ROOT / "data/math/tables_voice_provenance.json").read_text(encoding="utf-8"))
        expected_tables = {(operation, number) for operation in ("addition", "subtraction", "multiplication", "division") for number in range(1, 16)}
        if len(tables) != 60 or {(table["operation"], table["number"]) for table in tables} != expected_tables:
            errors.append("Expected 15 tables for each of the four operations.")
        ids = set()
        for table in tables:
            op, n = table["operation"], table["number"]
            if len(table["rows"]) != 15:
                errors.append(f"Table {op}/{n} must have 15 equations.")
            for step, row in enumerate(table["rows"], 1):
                expected = {"addition": (n, step, n + step, "más"),
                            "subtraction": (n + step, n, step, "menos"),
                            "multiplication": (n, step, n * step, "por"),
                            "division": (n * step, n, step, "dividido entre")}[op]
                a, b, result, word = expected
                key = f"{op}_{n:02}_{step:02}"
                text = f"{a} {word} {b}, igual a {result}."
                if (row["a"], row["b"], row["result"], row["step"], row["id"], row["text"]) != (a, b, result, step, key, text):
                    errors.append(f"Incorrect table equation: {key}")
                if key in ids:
                    errors.append(f"Repeated table equation ID: {key}")
                ids.add(key)
                line, record = lines[key], provenance["clips"][key]
                filename = key + ".mp3"
                data = (ROOT / "assets/audio/llama/tables" / filename).read_bytes()
                if line != dict(file=filename, text=text) or record["file"] != filename:
                    errors.append(f"Equation/narration mismatch: {key}")
                if len(data) < 1000 or hashlib.sha256(data).hexdigest() != record["sha256"] or hashlib.sha256(text.encode("utf-8")).hexdigest() != record["text_sha256"]:
                    errors.append(f"Missing or stale offline narration: {key}")
        if len(ids) != 900 or ids != set(lines) or ids != set(provenance["clips"]):
            errors.append("Incomplete 900-equation narration catalog.")
        if provenance["voice"] != "es-PE-CamilaNeural" or provenance["rate"] != "-5%":
            errors.append("Table voice differs from the llama's established voice.")
    except (OSError, ValueError, KeyError, TypeError) as error:
        errors.append(f"Could not audit operation tables: {error}")
    return errors


if __name__ == "__main__":
    errors = audit_operation_tables()
    print("\n".join(errors) if errors else "OK: 60 tables, 900 equations and 900 complete local narration clips.")
    raise SystemExit(bool(errors))
