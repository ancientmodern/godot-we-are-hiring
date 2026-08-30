"""Verify the exact, reproducible production-asset closure for the hiring build."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import struct
import sys
import xml.etree.ElementTree as ET
from pathlib import Path, PurePosixPath
from typing import Any


MANIFEST_RELATIVE = Path("assets/hiring_assets.json")
ALLOWED_KINDS = {"texture", "font", "license"}
SHA256_RE = re.compile(r"[0-9A-F]{64}")
PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
FONT_SIGNATURES = {b"\x00\x01\x00\x00", b"OTTO", b"ttcf", b"true"}
BASE_FIELDS = {"id", "path", "kind", "resource_type", "runtime", "bytes", "sha256"}


class VerificationError(RuntimeError):
    """Raised when the checked-in asset closure is inconsistent."""


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def _relative_from_res_path(value: object) -> Path:
    if not isinstance(value, str) or not value.startswith("res://"):
        raise VerificationError(f"asset path must be a res:// string: {value!r}")
    relative_text = value.removeprefix("res://")
    pure = PurePosixPath(relative_text)
    if not relative_text or pure.is_absolute() or "." in pure.parts or ".." in pure.parts:
        raise VerificationError(f"asset path is not canonical and relative: {value!r}")
    if pure.as_posix() != relative_text:
        raise VerificationError(f"asset path must use canonical forward slashes: {value!r}")
    return Path(*pure.parts)


def _load_manifest(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise VerificationError(f"cannot read {path}: {exc}") from exc
    if not isinstance(payload, dict):
        raise VerificationError("manifest root must be an object")
    if payload.get("schema") != 1:
        raise VerificationError(f"unsupported manifest schema: {payload.get('schema')!r}")
    if set(payload) != {"schema", "managed_globs", "assets"}:
        raise VerificationError("manifest root must contain exactly schema, managed_globs, and assets")
    if not isinstance(payload["managed_globs"], list) or not payload["managed_globs"]:
        raise VerificationError("managed_globs must be a nonempty array")
    if not isinstance(payload["assets"], list) or not payload["assets"]:
        raise VerificationError("assets must be a nonempty array")
    return payload


def _inspect_png(path: Path) -> tuple[int, int, bool]:
    data = path.read_bytes()
    if len(data) < 33 or data[:8] != PNG_SIGNATURE:
        raise VerificationError(f"{path} is not a complete PNG")
    chunk_length = struct.unpack(">I", data[8:12])[0]
    if data[12:16] != b"IHDR" or chunk_length != 13:
        raise VerificationError(f"{path} has no canonical PNG IHDR")
    width, height, bit_depth, color_type = struct.unpack(">IIBB", data[16:26])
    if width <= 0 or height <= 0 or bit_depth <= 0:
        raise VerificationError(f"{path} has invalid PNG dimensions or bit depth")
    has_transparency_chunk = False
    offset = 8
    while offset + 12 <= len(data):
        length = struct.unpack(">I", data[offset : offset + 4])[0]
        chunk_end = offset + 12 + length
        if chunk_end > len(data):
            raise VerificationError(f"{path} contains a truncated PNG chunk")
        chunk_type = data[offset + 4 : offset + 8]
        if chunk_type == b"tRNS":
            has_transparency_chunk = True
        offset = chunk_end
        if chunk_type == b"IEND":
            break
    has_alpha = color_type in {4, 6} or has_transparency_chunk
    return width, height, has_alpha


def _svg_number(value: object, label: str, path: Path) -> int:
    if not isinstance(value, str) or not re.fullmatch(r"[0-9]+(?:\.0+)?", value):
        raise VerificationError(f"{path} has a non-pixel or missing SVG {label}: {value!r}")
    return int(float(value))


def _inspect_svg(path: Path) -> tuple[int, int, bool]:
    try:
        root = ET.parse(path).getroot()
    except (OSError, ET.ParseError) as exc:
        raise VerificationError(f"cannot parse SVG {path}: {exc}") from exc
    if root.tag.rsplit("}", 1)[-1] != "svg":
        raise VerificationError(f"{path} root element is not svg")
    width = _svg_number(root.get("width"), "width", path)
    height = _svg_number(root.get("height"), "height", path)
    view_box = root.get("viewBox", "").split()
    try:
        view_box_matches = len(view_box) == 4 and float(view_box[2]) == width and float(view_box[3]) == height
    except ValueError:
        view_box_matches = False
    if not view_box_matches:
        raise VerificationError(f"{path} viewBox does not match declared dimensions")
    alpha_attributes = ("opacity", "fill-opacity", "stroke-opacity")
    has_alpha = False
    for element in root.iter():
        for attribute in alpha_attributes:
            raw_value = element.get(attribute)
            if raw_value is None:
                continue
            try:
                if float(raw_value) < 1.0:
                    has_alpha = True
            except ValueError as exc:
                raise VerificationError(f"{path} has invalid SVG {attribute}={raw_value!r}") from exc
    return width, height, has_alpha


def _check_texture(entry: dict[str, Any], path: Path) -> None:
    if set(entry) != BASE_FIELDS | {"width", "height", "alpha"}:
        raise VerificationError(f"texture {entry.get('id')!r} has missing or unexpected fields")
    if entry.get("resource_type") != "Texture2D" or entry.get("runtime") is not True:
        raise VerificationError(f"texture {entry.get('id')!r} must be a runtime Texture2D")
    if path.suffix.lower() == ".png":
        actual = _inspect_png(path)
    elif path.suffix.lower() == ".svg":
        actual = _inspect_svg(path)
    else:
        raise VerificationError(f"texture {entry.get('id')!r} has unsupported suffix {path.suffix!r}")
    expected = (entry.get("width"), entry.get("height"), entry.get("alpha"))
    if not isinstance(expected[0], int) or not isinstance(expected[1], int) or not isinstance(expected[2], bool):
        raise VerificationError(f"texture {entry.get('id')!r} needs integer dimensions and boolean alpha")
    if actual != expected:
        raise VerificationError(
            f"texture {entry.get('id')!r} metadata mismatch: expected {expected}, found {actual}"
        )


def _check_font(entry: dict[str, Any], path: Path) -> None:
    if set(entry) != BASE_FIELDS:
        raise VerificationError(f"font {entry.get('id')!r} has missing or unexpected fields")
    if entry.get("resource_type") != "FontFile" or entry.get("runtime") is not True:
        raise VerificationError(f"font {entry.get('id')!r} must be a runtime FontFile")
    if path.suffix.lower() not in {".ttf", ".otf", ".ttc"}:
        raise VerificationError(f"font {entry.get('id')!r} has an unsupported suffix")
    if path.read_bytes()[:4] not in FONT_SIGNATURES:
        raise VerificationError(f"font {entry.get('id')!r} has an invalid sfnt signature")


def _check_license(entry: dict[str, Any], path: Path, entries_by_id: dict[str, dict[str, Any]]) -> None:
    if set(entry) != BASE_FIELDS | {"license_for"}:
        raise VerificationError(f"license {entry.get('id')!r} has missing or unexpected fields")
    if entry.get("resource_type") != "" or entry.get("runtime") is not False:
        raise VerificationError(f"license {entry.get('id')!r} must be a non-runtime plain file")
    if path.suffix.lower() != ".txt":
        raise VerificationError(f"license {entry.get('id')!r} must be a text file")
    licensed_id = entry.get("license_for")
    if not isinstance(licensed_id, str) or entries_by_id.get(licensed_id, {}).get("kind") != "font":
        raise VerificationError(f"license {entry.get('id')!r} must reference a declared font")
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise VerificationError(f"cannot read font license {path}: {exc}") from exc
    if "SIL Open Font License" not in text or "Version 1.1" not in text:
        raise VerificationError(f"font license {path} is not the expected OFL 1.1 text")


def verify(root: Path, manifest_path: Path) -> tuple[int, int]:
    root = root.resolve()
    manifest_path = manifest_path.resolve()
    try:
        manifest_path.relative_to(root)
    except ValueError as exc:
        raise VerificationError("manifest must remain inside the project root") from exc
    payload = _load_manifest(manifest_path)
    assets = payload["assets"]

    ids: set[str] = set()
    folded_paths: set[str] = set()
    declared_paths: set[str] = set()
    entries_by_id: dict[str, dict[str, Any]] = {}
    resolved_entries: list[tuple[dict[str, Any], Path]] = []
    for index, value in enumerate(assets):
        if not isinstance(value, dict):
            raise VerificationError(f"asset entry {index} must be an object")
        entry = value
        asset_id = entry.get("id")
        if not isinstance(asset_id, str) or not re.fullmatch(r"[a-z][a-z0-9_]*", asset_id):
            raise VerificationError(f"asset entry {index} has invalid id {asset_id!r}")
        if asset_id in ids:
            raise VerificationError(f"duplicate asset id: {asset_id}")
        ids.add(asset_id)
        entries_by_id[asset_id] = entry

        relative = _relative_from_res_path(entry.get("path"))
        canonical = relative.as_posix()
        folded = canonical.casefold()
        if folded in folded_paths:
            raise VerificationError(f"duplicate or case-alias asset path: {canonical}")
        folded_paths.add(folded)
        declared_paths.add(canonical)
        path = (root / relative).resolve()
        try:
            path.relative_to(root)
        except ValueError as exc:
            raise VerificationError(f"asset escapes the project root: {canonical}") from exc
        if not path.is_file():
            raise VerificationError(f"declared asset is missing: {canonical}")
        resolved_entries.append((entry, path))

    managed_paths: set[str] = set()
    seen_globs: set[str] = set()
    for value in payload["managed_globs"]:
        pure_pattern = PurePosixPath(value) if isinstance(value, str) else None
        if (
            not isinstance(value, str)
            or not value
            or "\\" in value
            or ":" in value
            or pure_pattern is None
            or pure_pattern.is_absolute()
            or "." in pure_pattern.parts
            or ".." in pure_pattern.parts
        ):
            raise VerificationError(f"managed glob must be a safe relative pattern: {value!r}")
        if value in seen_globs:
            raise VerificationError(f"duplicate managed glob: {value}")
        seen_globs.add(value)
        matches = [path for path in root.glob(value) if path.is_file()]
        if not matches:
            raise VerificationError(f"managed glob matched no files: {value}")
        for path in matches:
            managed_paths.add(path.relative_to(root).as_posix())
    if managed_paths != declared_paths:
        missing = sorted(managed_paths - declared_paths)
        absent = sorted(declared_paths - managed_paths)
        raise VerificationError(
            f"declared/present closure mismatch; undeclared={missing}, outside_managed_scope={absent}"
        )

    total_bytes = 0
    for entry, path in resolved_entries:
        asset_id = str(entry["id"])
        kind = entry.get("kind")
        if kind not in ALLOWED_KINDS:
            raise VerificationError(f"asset {asset_id!r} has invalid kind {kind!r}")
        expected_size = entry.get("bytes")
        expected_hash = entry.get("sha256")
        if not isinstance(expected_size, int) or expected_size <= 0:
            raise VerificationError(f"asset {asset_id!r} has invalid byte count")
        if not isinstance(expected_hash, str) or SHA256_RE.fullmatch(expected_hash) is None:
            raise VerificationError(f"asset {asset_id!r} has invalid uppercase SHA-256")
        actual_size = path.stat().st_size
        actual_hash = _sha256(path)
        if actual_size != expected_size or actual_hash != expected_hash:
            raise VerificationError(
                f"asset {asset_id!r} fingerprint mismatch: expected {expected_size}/{expected_hash}, "
                f"found {actual_size}/{actual_hash}"
            )
        total_bytes += actual_size

        if kind == "texture":
            _check_texture(entry, path)
        elif kind == "font":
            _check_font(entry, path)
        else:
            _check_license(entry, path, entries_by_id)

    return len(resolved_entries), total_bytes


def main() -> int:
    project_root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=project_root)
    parser.add_argument("--manifest", type=Path)
    args = parser.parse_args()
    root = args.root.resolve()
    manifest = args.manifest.resolve() if args.manifest else root / MANIFEST_RELATIVE
    try:
        count, total_bytes = verify(root, manifest)
    except VerificationError as exc:
        print(f"HIRING_ASSET_MANIFEST_FAILURE: {exc}", file=sys.stderr)
        return 1
    print(f"HIRING_ASSET_MANIFEST_PASS: assets={count}, bytes={total_bytes}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
