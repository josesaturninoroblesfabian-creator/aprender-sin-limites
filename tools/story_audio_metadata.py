"""Portable word-timing hashes, including manifests made before a Git checkout."""
import hashlib


def timing_sha256(data: bytes) -> str:
    return hashlib.sha256(data.replace(b"\r\n", b"\n")).hexdigest()


def timing_matches(data: bytes, expected: str | None) -> bool:
    normalized = data.replace(b"\r\n", b"\n")
    # Older Windows manifests hashed CRLF; Git stores these JSON files with LF.
    return expected in {
        timing_sha256(normalized),
        hashlib.sha256(normalized.replace(b"\n", b"\r\n")).hexdigest(),
    }
