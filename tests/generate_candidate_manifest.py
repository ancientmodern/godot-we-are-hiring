"""Generate a reproducible source manifest for a non-Git candidate build."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
from pathlib import Path, PurePosixPath


HIRING_ASSET_MANIFEST = Path("assets/hiring_assets.json")


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def _hiring_asset_files(root: Path) -> list[Path]:
    """Read the authoritative player-facing asset closure from its manifest."""

    manifest_path = root / HIRING_ASSET_MANIFEST
    try:
        payload = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise ValueError(f"cannot read hiring asset manifest: {exc}") from exc
    if not isinstance(payload, dict) or payload.get("schema") != 1:
        raise ValueError("hiring asset manifest must be a schema-one object")
    assets = payload.get("assets")
    if not isinstance(assets, list) or not assets:
        raise ValueError("hiring asset manifest must contain a nonempty asset array")

    paths = [manifest_path]
    folded_paths: set[str] = set()
    for index, entry in enumerate(assets):
        if not isinstance(entry, dict):
            raise ValueError(f"hiring asset entry {index} must be an object")
        value = entry.get("path")
        if not isinstance(value, str) or not value.startswith("res://"):
            raise ValueError(f"hiring asset entry {index} needs a res:// path")
        relative_text = value.removeprefix("res://")
        pure = PurePosixPath(relative_text)
        if not relative_text or pure.is_absolute() or "." in pure.parts or ".." in pure.parts:
            raise ValueError(f"hiring asset path is not canonical: {value!r}")
        if pure.as_posix() != relative_text:
            raise ValueError(f"hiring asset path must use forward slashes: {value!r}")
        folded = relative_text.casefold()
        if folded in folded_paths:
            raise ValueError(f"duplicate or case-alias hiring asset path: {value!r}")
        folded_paths.add(folded)
        path = root.joinpath(*pure.parts).resolve()
        try:
            path.relative_to(root.resolve())
        except ValueError as exc:
            raise ValueError(f"hiring asset path escapes the project root: {value!r}") from exc
        paths.append(path)

    missing = [path for path in paths if not path.is_file()]
    if missing:
        raise FileNotFoundError(f"hiring asset files are missing: {missing}")
    return paths


def _candidate_files(root: Path) -> list[Path]:
    fixed = [
        root / "project.godot",
        root / "hiring_main.tscn",
        root / "README.md",
        root / "we-are-hiring-creative-bible.md",
    ] + _hiring_asset_files(root)
    discovered: list[Path] = []
    for directory, suffixes in (
        (root / "src", {".gd"}),
        (root / "tests", {".gd", ".py", ".ps1"}),
        (root / "docs", {".md"}),
    ):
        discovered.extend(
            path for path in directory.rglob("*") if path.is_file() and path.suffix.lower() in suffixes
        )
    paths = sorted(set(fixed + discovered), key=lambda path: path.relative_to(root).as_posix())
    missing = [path for path in paths if not path.is_file()]
    if missing:
        raise FileNotFoundError(f"candidate source files are missing: {missing}")
    return paths


def _production_files(root: Path) -> list[Path]:
    """Return the complete runtime dependency closure for the hiring build.

    The old creature-demo source remains in this shared workspace for provenance,
    but project.godot points only at hiring_main.tscn. The production fingerprint
    therefore names the exact scene, scripts and manifest-declared player-facing
    assets used by that entry point. The broader source-tree fingerprint below
    still covers all candidate tests, documentation and retained source files.
    """

    return [
        root / "project.godot",
        root / "hiring_main.tscn",
        root / "src" / "hiring_main.gd",
        root / "src" / "hiring_model.gd",
        root / "src" / "hiring_content.gd",
        root / "src" / "hiring_director.gd",
        root / "src" / "night_interaction_state.gd",
        root / "src" / "office_audio.gd",
    ] + _hiring_asset_files(root)


def _tree_fingerprint(root: Path, paths: list[Path]) -> tuple[str, int]:
    digest = hashlib.sha256()
    total_bytes = 0
    for path in sorted(paths, key=lambda candidate: candidate.relative_to(root).as_posix()):
        relative = path.relative_to(root).as_posix()
        file_hash = _sha256(path)
        total_bytes += path.stat().st_size
        digest.update(relative.encode("utf-8"))
        digest.update(b"\0")
        digest.update(file_hash.encode("ascii"))
        digest.update(b"\n")
    return digest.hexdigest().upper(), total_bytes


def main() -> int:
    parser = argparse.ArgumentParser()
    root = Path(__file__).resolve().parents[1]
    parser.add_argument("--output", type=Path, default=root / "artifacts" / "candidate_manifest.json")
    args = parser.parse_args()

    files = _candidate_files(root)
    production_files = _production_files(root)
    missing_production = [path for path in production_files if not path.is_file()]
    if missing_production:
        raise FileNotFoundError(f"production source files are missing: {missing_production}")
    if not set(production_files).issubset(files):
        raise AssertionError("production dependency closure is not contained in the candidate manifest")
    entries: list[dict[str, object]] = []
    tree_digest = hashlib.sha256()
    total_bytes = 0
    for path in files:
        relative = path.relative_to(root).as_posix()
        file_hash = _sha256(path)
        size = path.stat().st_size
        total_bytes += size
        entries.append({"path": relative, "bytes": size, "sha256": file_hash})
        tree_digest.update(relative.encode("utf-8"))
        tree_digest.update(b"\0")
        tree_digest.update(file_hash.encode("ascii"))
        tree_digest.update(b"\n")

    production_hash, production_bytes = _tree_fingerprint(root, production_files)
    payload = {
        "schema": 2,
        "generated_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        "production_tree_sha256": production_hash,
        "production_file_count": len(production_files),
        "production_total_bytes": production_bytes,
        "source_tree_sha256": tree_digest.hexdigest().upper(),
        "file_count": len(entries),
        "total_bytes": total_bytes,
        "files": entries,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        "HIRING_CANDIDATE_MANIFEST_PASS: "
        f"production_files={len(production_files)}, production_bytes={production_bytes}, "
        f"production_tree_sha256={production_hash}, files={len(entries)}, bytes={total_bytes}, "
        f"source_tree_sha256={payload['source_tree_sha256']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
