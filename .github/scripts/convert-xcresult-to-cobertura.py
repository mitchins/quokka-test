#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any, Dict, Iterable


def _to_int(value: Any) -> int | None:
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _extract_json_report(result_bundle_path: Path) -> Dict[str, Any]:
    try:
        command = [
            "xcrun",
            "xccov",
            "view",
            "--report",
            "--json",
            str(result_bundle_path),
        ]
        completed = subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=True,
        )
        return json.loads(completed.stdout)
    except Exception as error:
        fallback = subprocess.run(
            [
                "xcrun",
                "xcresulttool",
                "get",
                "--legacy",
                "object",
                "--path",
                str(result_bundle_path),
                "--format",
                "json",
            ],
            capture_output=True,
            text=True,
            check=True,
        )
        payload = json.loads(fallback.stdout)
        if not payload:
            raise RuntimeError(f"Unable to parse coverage JSON for {result_bundle_path}") from error
        return payload


def _extract_json_archive(result_bundle_path: Path) -> Dict[str, Any]:
    completed = subprocess.run(
        [
            "xcrun",
            "xccov",
            "view",
            "--archive",
            "--json",
            str(result_bundle_path),
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    payload = json.loads(completed.stdout)
    if not isinstance(payload, dict):
        raise RuntimeError(f"Unexpected archive JSON shape for {result_bundle_path}")
    return payload


def _is_source_candidate(node: Dict[str, Any]) -> bool:
    if not isinstance(node.get("path"), str):
        return False
    keys = {"lineCoverage", "lines", "lineData", "coveredLines", "executableLines"}
    return any(key in node for key in keys)


def _collect_file_nodes(root: Any, seen: set[int], out: list[Dict[str, Any]]) -> None:
    if isinstance(root, dict):
        if id(root) in seen:
            return
        seen.add(id(root))
        if _is_source_candidate(root):
            out.append(root)
        for value in root.values():
            _collect_file_nodes(value, seen, out)
        return
    if isinstance(root, list):
        for item in root:
            _collect_file_nodes(item, seen, out)


def _iter_line_ints(value: Any) -> Iterable[int]:
    if value is None:
        return []
    if isinstance(value, int):
        return [value]
    if isinstance(value, str):
        parts = [part.strip() for part in value.split(",") if part.strip()]
        return filter(None, (_to_int(part) for part in parts))
    elif isinstance(value, list):
        for item in value:
            if isinstance(item, dict):
                line = _to_int(item.get("lineNumber")) or _to_int(item.get("line")) or _to_int(item.get("line_number"))
                if line is not None:
                    yield line
            elif isinstance(item, int):
                yield item
    return []


def _line_hits_from_mapping(value: Any) -> Dict[int, int]:
    if value is None:
        return {}
    if isinstance(value, dict):
        if not value:
            return {}
        if all(_to_int(k) is not None for k in value.keys()):
            return {
                int(str(line)): _to_int(count) or 0
                for line, count in value.items()
                if _to_int(line) is not None
            }
        if "coveredLines" in value:
            covered = set(_iter_line_ints(value.get("coveredLines")))
            executable = set(_iter_line_ints(value.get("executableLines")))
            return {line: (1 if line in covered else 0) for line in executable}
        if "lines" in value and isinstance(value["lines"], list):
            result: Dict[int, int] = {}
            for item in value["lines"]:
                if isinstance(item, dict):
                    line = _to_int(item.get("line")) or _to_int(item.get("lineNumber")) or _to_int(
                        item.get("line_number")
                    )
                    if line is None:
                        continue
                    hits = (
                        _to_int(item.get("executionCount"))
                        or _to_int(item.get("hits"))
                        or _to_int(item.get("count"))
                        or 0
                    )
                    result[line] = hits
            return result
    if isinstance(value, list):
        result: Dict[int, int] = {}
        for item in value:
            if isinstance(item, dict):
                line = _to_int(item.get("lineNumber")) or _to_int(item.get("line")) or _to_int(
                    item.get("line_number")
                )
                if line is None:
                    continue
                hits = (
                    _to_int(item.get("executionCount"))
                    or _to_int(item.get("hits"))
                    or _to_int(item.get("count"))
                    or 0
                )
                result[line] = hits
        return result
    return {}


def _line_hits_from_entry(entry: Dict[str, Any]) -> Dict[int, int]:
    for key in ("lineCoverage", "lines", "lineData", "coverage", "lineCoverageData"):
        if key in entry:
            hits = _line_hits_from_mapping(entry.get(key))
            if hits:
                return hits
    if "coveredLines" in entry or "executableLines" in entry:
        return _line_hits_from_mapping(entry)
    if "lineCoverage" not in entry and "lines" not in entry and "lineData" not in entry:
        return {}
    return {}


def _resolve_path(raw: str, root: Path) -> Path:
    candidate = Path(raw)
    if candidate.is_absolute():
        try:
            return candidate.relative_to(root)
        except ValueError:
            if candidate.exists():
                return candidate
    return candidate


def _source_files_from_archive(payload: Dict[str, Any], repository_root: Path) -> list[tuple[str, Dict[int, int]]]:
    source_files: list[tuple[str, Dict[int, int]]] = []

    for raw_path, entries in payload.items():
        if not isinstance(raw_path, str):
            continue

        resolved = _resolve_path(raw_path.strip(), repository_root)
        if resolved.suffix.lower() not in {".swift", ".m", ".mm", ".c", ".cpp", ".hpp", ".h"}:
            continue
        if not isinstance(entries, list):
            continue

        line_hits: Dict[int, int] = {}
        for entry in entries:
            if not isinstance(entry, dict):
                continue
            if not entry.get("isExecutable"):
                continue
            line = _to_int(entry.get("line"))
            if line is None:
                continue
            line_hits[line] = _to_int(entry.get("executionCount")) or 0

        if not line_hits:
            continue

        rel_path = str(resolved).replace("\\", "/")
        source_files.append((rel_path, line_hits))

    return source_files


def _to_cobertura_xml(result_path: Path, output_path: Path, repository_root: Path) -> None:
    source_files = _source_files_from_archive(_extract_json_archive(result_path), repository_root)

    if not source_files:
        payload = _extract_json_report(result_path)
        file_nodes: list[Dict[str, Any]] = []
        _collect_file_nodes(payload, set(), file_nodes)

        for node in file_nodes:
            raw_path = node.get("path") or node.get("name") or ""
            if not isinstance(raw_path, str) or not raw_path.strip():
                continue
            resolved = _resolve_path(raw_path.strip(), repository_root)
            if resolved.suffix.lower() not in {".swift", ".m", ".mm", ".c", ".cpp", ".hpp", ".h"}:
                continue
            line_hits = _line_hits_from_entry(node)
            if not line_hits:
                continue
            rel_path = str(resolved).replace("\\", "/")
            source_files.append((rel_path, line_hits))

    if not source_files:
        raise RuntimeError(f"No source lines discovered in {result_path}")

    total_covered = sum(1 for _, hits in source_files for value in hits.values() if value > 0)
    total_executable = sum(len(hits) for _, hits in source_files)
    line_rate = float(total_covered) / float(total_executable) if total_executable else 0.0

    coverage = ET.Element(
        "coverage",
        {
            "line-rate": f"{line_rate:.6f}",
            "line-covered": str(total_covered),
            "line-valid": str(total_executable),
            "branch-rate": "0",
            "branches-covered": "0",
            "branches-valid": "0",
            "timestamp": str(int(time.time())),
            "version": "QuokkaTestXCCov2Cobertura",
        },
    )

    sources = ET.SubElement(coverage, "sources")
    ET.SubElement(sources, "source").text = str(repository_root)

    packages = ET.SubElement(coverage, "packages")
    package_lookup: dict[str, list[tuple[str, Dict[int, int]]]] = {}

    for rel_path, hits in sorted(source_files, key=lambda item: item[0]):
        package = "Unknown"
        rel_obj = Path(rel_path)
        if len(rel_obj.parts) >= 2:
            package = rel_obj.parts[0]
        package_lookup.setdefault(package, []).append((rel_path, hits))

    for package_name, files in package_lookup.items():
        package_lines = sum(len(hits) for _, hits in files)
        package_covered = sum(1 for _, hits in files for value in hits.values() if value > 0)
        package_line_rate = float(package_covered) / float(package_lines) if package_lines else 0.0
        package = ET.SubElement(
            packages,
            "package",
            {
                "name": package_name,
                "line-rate": f"{package_line_rate:.6f}",
                "branch-rate": "0",
                "complexity": "0",
            },
        )
        classes = ET.SubElement(package, "classes")

        for rel_path, hits in files:
            file_path = Path(rel_path)
            file_name = file_path.name
            file_lines = len(hits)
            file_covered = sum(1 for value in hits.values() if value > 0)
            file_line_rate = float(file_covered) / float(file_lines) if file_lines else 0.0
            class_node = ET.SubElement(
                classes,
                "class",
                {
                    "name": file_path.with_suffix("").as_posix().replace("/", "."),
                    "filename": rel_path,
                    "line-rate": f"{file_line_rate:.6f}",
                    "branch-rate": "0",
                    "complexity": "0",
                },
            )
            lines = ET.SubElement(class_node, "lines")
            for line in sorted(hits):
                ET.SubElement(
                    lines,
                    "line",
                    {
                        "number": str(line),
                        "hits": str(hits[line]),
                        "branch": "false",
                    },
                )

            methods_node = ET.SubElement(class_node, "methods")
            ET.SubElement(
                methods_node,
                "method",
                {
                    "name": file_name,
                    "signature": "",
                    "line-rate": f"{file_line_rate:.6f}",
                    "branch-rate": "0",
                },
            )

    tree = ET.ElementTree(coverage)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    tree.write(output_path, encoding="utf-8", xml_declaration=True)
    print(f"Wrote {output_path}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("result_bundle")
    parser.add_argument("output_xml")
    args = parser.parse_args()

    result_path = Path(args.result_bundle)
    output_path = Path(args.output_xml)
    if not result_path.exists():
        raise SystemExit(f"Missing result bundle: {result_path}")

    repository_root = Path.cwd().resolve()
    _to_cobertura_xml(result_path, output_path, repository_root)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        raise SystemExit(str(exc))
