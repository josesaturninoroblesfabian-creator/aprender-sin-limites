"""Build the four offline table catalogs and their complete spoken equations."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def build():
    tables, clips = [], {}
    for operation in ("addition", "subtraction", "multiplication", "division"):
        for number in range(1, 16):
            rows = []
            for step in range(1, 16):
                if operation == "addition":
                    a, b, result, word = number, step, number + step, "más"
                elif operation == "subtraction":
                    a, b, result, word = number + step, number, step, "menos"
                elif operation == "multiplication":
                    a, b, result, word = number, step, number * step, "por"
                else:
                    a, b, result, word = number * step, number, step, "dividido entre"
                key = f"{operation}_{number:02}_{step:02}"
                text = f"{a} {word} {b}, igual a {result}."
                rows.append(dict(id=key, a=a, b=b, result=result, step=step, text=text))
                clips[key] = dict(file=key + ".mp3", text=text)
            tables.append(dict(operation=operation, number=number, rows=rows))
    folder = ROOT / "data/math"
    for filename, data in [("operation_tables.json", dict(version=1, tables=tables)),
                           ("tables_voice_lines.json", dict(clips=clips))]:
        (folder / filename).write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Built {len(tables)} tables, {len(clips)} complete equations.")


if __name__ == "__main__":
    build()
