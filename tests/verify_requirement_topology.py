"""Verify one-to-one topology between the canonical requirements and evidence ledger."""

from __future__ import annotations

import argparse
import collections
import re
from pathlib import Path


REQUIREMENT_ID = re.compile(r"^[A-Z][A-Z0-9]*(?:-[A-Z0-9]+)+$")
EXPECTED_REQUIREMENT_COUNT = 272
ALLOWED_STATUSES = {"Verified", "Partial", "Implemented-unverified", "Unverified"}


def _table_rows(path: Path) -> list[list[str]]:
    rows: list[list[str]] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line.startswith("|") or not line.endswith("|"):
            continue
        cells = [cell.strip() for cell in line[1:-1].split("|")]
        if cells and REQUIREMENT_ID.fullmatch(cells[0]):
            rows.append(cells)
    return rows


def _assert_unique(ids: list[str], label: str) -> None:
    duplicates = sorted(key for key, count in collections.Counter(ids).items() if count > 1)
    if duplicates:
        raise AssertionError(f"{label} contains duplicate requirement IDs: {duplicates}")


def main() -> int:
    parser = argparse.ArgumentParser()
    root = Path(__file__).resolve().parents[1]
    parser.add_argument("--matrix", type=Path, default=root / "docs" / "requirements_matrix.md")
    parser.add_argument("--ledger", type=Path, default=root / "docs" / "requirement_evidence_ledger.md")
    args = parser.parse_args()

    matrix_rows = _table_rows(args.matrix)
    matrix_ids = [row[0] for row in matrix_rows]
    _assert_unique(matrix_ids, "requirements matrix")
    if len(matrix_ids) != EXPECTED_REQUIREMENT_COUNT:
        raise AssertionError(
            f"requirements matrix has {len(matrix_ids)} IDs; expected {EXPECTED_REQUIREMENT_COUNT}"
        )

    matrix_set = set(matrix_ids)
    # The ledger begins with a compact evidence-key table. Filter by the
    # canonical matrix IDs so evidence aliases can never masquerade as scope.
    ledger_rows = [row for row in _table_rows(args.ledger) if row[0] in matrix_set]
    ledger_ids = [row[0] for row in ledger_rows]
    _assert_unique(ledger_ids, "evidence ledger")

    missing = sorted(matrix_set - set(ledger_ids))
    extra = sorted(set(ledger_ids) - matrix_set)
    if missing or extra:
        raise AssertionError(f"ledger topology mismatch: missing={missing}, extra={extra}")
    if ledger_ids != matrix_ids:
        raise AssertionError("ledger requirement order differs from the canonical matrix")

    status_counts: collections.Counter[str] = collections.Counter()
    for row in ledger_rows:
        if len(row) != 6:
            raise AssertionError(f"ledger row {row[0]} has {len(row)} cells; expected 6")
        status = row[1]
        if status not in ALLOWED_STATUSES:
            raise AssertionError(f"ledger row {row[0]} has invalid status {status!r}")
        status_counts[status] += 1
        if status != "Verified" and row[5] in {"", "—", "无"}:
            raise AssertionError(f"non-Verified ledger row {row[0]} does not name its remaining gap")

    print(
        "HIRING_REQUIREMENT_TOPOLOGY_PASS: "
        f"requirements={len(matrix_ids)}, statuses={dict(sorted(status_counts.items()))}, "
        "missing=0, extra=0, duplicates=0"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
