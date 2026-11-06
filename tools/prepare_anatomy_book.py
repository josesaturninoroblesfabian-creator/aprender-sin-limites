"""Convert a local PDF to the offline reader's page pack (PyMuPDF and Pillow)."""

import argparse
import io
import json
from pathlib import Path
from tempfile import NamedTemporaryFile
from zipfile import ZipFile

import pymupdf
from PIL import Image


def prepare(source: Path, output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    with NamedTemporaryFile(dir=output.parent, suffix=".tmp", delete=False) as temp:
        candidate = Path(temp.name)
    try:
        with pymupdf.open(source) as pdf, ZipFile(candidate, "w") as pack:
            if not pdf.is_pdf or pdf.needs_pass or not pdf.page_count:
                raise ValueError("Se requiere un PDF legible, sin contraseña.")
            pack.writestr("manifest.json", json.dumps({"version": 1, "pages": pdf.page_count}))
            for number, page in enumerate(pdf, 1):
                factor = min(1600 / page.rect.width, 2000 / page.rect.height)
                pixels = page.get_pixmap(matrix=pymupdf.Matrix(factor, factor), colorspace=pymupdf.csRGB)
                image = Image.frombytes("RGB", (pixels.width, pixels.height), pixels.samples)
                encoded = io.BytesIO()
                image.save(encoded, format="WEBP", quality=84, method=2)
                pack.writestr(f"pages/{number:04}.webp", encoded.getvalue())
        candidate.replace(output)
        print(f"{output.name}: {number} páginas, {output.stat().st_size / 1048576:.1f} MiB")
    finally:
        candidate.unlink(missing_ok=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pdf", type=Path)
    parser.add_argument("pack", type=Path)
    args = parser.parse_args()
    prepare(args.pdf, args.pack)
