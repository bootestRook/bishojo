#!/usr/bin/env python3
"""Export and query Godot extension_api.json dumps."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any, Iterable


SCRIPT_DIR = Path(__file__).resolve().parent
SKILL_DIR = SCRIPT_DIR.parent
DEFAULT_API_PATH = SKILL_DIR.parent / "extension_api.json"


JsonObject = dict[str, Any]


def default_api_candidates() -> list[Path]:
    candidates = [
        SKILL_DIR.parent / "extension_api.json",
        Path.cwd() / "extension_api.json",
        Path.cwd().parent / "extension_api.json",
    ]
    parents = list(SKILL_DIR.parents)
    if len(parents) >= 3:
        candidates.append(parents[2] / "extension_api_check" / "extension_api.json")
    return candidates


def resolve_api_path(path: Path | None) -> Path:
    if path:
        return path.expanduser().resolve()
    for candidate in default_api_candidates():
        if candidate.exists():
            return candidate.resolve()
    return DEFAULT_API_PATH.resolve()


def default_api_output_path() -> Path:
    for candidate in default_api_candidates():
        if candidate.exists():
            return candidate.resolve()
    return DEFAULT_API_PATH.resolve()


def load_api(path: Path | None) -> JsonObject:
    resolved = resolve_api_path(path)
    if not resolved.exists():
        raise SystemExit(f"API file not found: {resolved}")
    try:
        return json.loads(resolved.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Invalid JSON in {resolved}: {exc}") from exc


def version_label(api: JsonObject) -> str:
    header = api.get("header", {})
    return header.get("version_full_name") or ".".join(
        str(header.get(key, "?"))
        for key in ("version_major", "version_minor", "version_patch")
    )


def norm(text: Any, case_sensitive: bool = False) -> str:
    value = "" if text is None else str(text)
    return value if case_sensitive else value.lower()


def matches(text: Any, query: str, case_sensitive: bool = False, exact: bool = False) -> bool:
    lhs = norm(text, case_sensitive)
    rhs = norm(query, case_sensitive)
    return lhs == rhs if exact else rhs in lhs


def return_type(method: JsonObject) -> str:
    if "return_value" in method:
        return method["return_value"].get("type", "Variant")
    return method.get("return_type", "void")


def format_argument(argument: JsonObject) -> str:
    name = argument.get("name", "arg")
    typ = argument.get("type", "Variant")
    text = f"{name}: {typ}"
    if "default_value" in argument:
        text += f" = {argument['default_value']}"
    return text


def format_method(method: JsonObject) -> str:
    args = ", ".join(format_argument(arg) for arg in method.get("arguments", []))
    prefix = "static " if method.get("is_static") else ""
    suffixes: list[str] = []
    if method.get("is_const"):
        suffixes.append("const")
    if method.get("is_vararg"):
        suffixes.append("vararg")
    if method.get("is_virtual"):
        suffixes.append("virtual")
    suffix = f" [{' '.join(suffixes)}]" if suffixes else ""
    return f"{prefix}{method.get('name', '<unnamed>')}({args}) -> {return_type(method)}{suffix}"


def section_items(api: JsonObject, section: str) -> list[JsonObject]:
    return [item for item in api.get(section, []) if isinstance(item, dict)]


def find_named(items: Iterable[JsonObject], name: str, case_sensitive: bool = False) -> JsonObject | None:
    for item in items:
        if matches(item.get("name"), name, case_sensitive=case_sensitive, exact=True):
            return item
    return None


def find_type(api: JsonObject, name: str, case_sensitive: bool = False) -> tuple[str, JsonObject] | None:
    for section in ("classes", "builtin_classes"):
        item = find_named(section_items(api, section), name, case_sensitive)
        if item:
            return section, item
    return None


def print_json(data: Any) -> None:
    print(json.dumps(data, ensure_ascii=False, indent=2))


def command_summary(args: argparse.Namespace) -> None:
    api = load_api(args.api)
    header = api.get("header", {})
    if args.json:
        print_json(
            {
                "version": header,
                "counts": {
                    "classes": len(api.get("classes", [])),
                    "builtin_classes": len(api.get("builtin_classes", [])),
                    "singletons": len(api.get("singletons", [])),
                    "utility_functions": len(api.get("utility_functions", [])),
                    "global_enums": len(api.get("global_enums", [])),
                    "native_structures": len(api.get("native_structures", [])),
                    "builtin_class_sizes": len(api.get("builtin_class_sizes", [])),
                    "builtin_class_member_offsets": len(api.get("builtin_class_member_offsets", [])),
                },
            }
        )
        return

    print(f"Godot API: {version_label(api)}")
    print(f"Precision: {header.get('precision', 'unknown')}")
    for key in (
        "classes",
        "builtin_classes",
        "singletons",
        "utility_functions",
        "global_enums",
        "native_structures",
        "builtin_class_sizes",
        "builtin_class_member_offsets",
    ):
        print(f"{key}: {len(api.get(key, []))}")


def command_list(args: argparse.Namespace) -> None:
    api = load_api(args.api)
    aliases = {
        "builtin-classes": "builtin_classes",
        "utility-functions": "utility_functions",
        "global-enums": "global_enums",
        "native-structures": "native_structures",
    }
    sections = (
        ["classes", "builtin_classes", "singletons", "utility_functions", "global_enums", "native_structures"]
        if args.section == "all"
        else [aliases.get(args.section, args.section)]
    )

    rows: list[dict[str, str]] = []
    for section in sections:
        for item in section_items(api, section):
            name = item.get("name", "")
            if args.filter and not matches(name, args.filter, args.case_sensitive):
                continue
            rows.append({"section": section, "name": name})

    rows.sort(key=lambda row: (row["section"], row["name"].lower()))
    if args.json:
        print_json(rows)
        return
    for row in rows[: args.limit]:
        print(f"{row['section']}: {row['name']}")
    if len(rows) > args.limit:
        print(f"... {len(rows) - args.limit} more")


def summarize_group(label: str, items: list[JsonObject], formatter, limit: int) -> None:
    if not items:
        return
    print(f"\n{label} ({len(items)}):")
    for item in items[:limit]:
        print(f"  {formatter(item)}")
    if len(items) > limit:
        print(f"  ... {len(items) - limit} more")


def command_class(args: argparse.Namespace) -> None:
    api = load_api(args.api)
    found = find_type(api, args.name, args.case_sensitive)
    if not found:
        raise SystemExit(f"Class or builtin class not found: {args.name}")
    section, item = found
    if args.json:
        print_json(item)
        return

    print(f"{item.get('name')} ({section})")
    if section == "classes":
        print(f"inherits: {item.get('inherits', '<none>')}")
        print(f"api_type: {item.get('api_type', 'unknown')}")
        print(f"instantiable: {item.get('is_instantiable', False)}")
        print(f"refcounted: {item.get('is_refcounted', False)}")
    else:
        print(f"keyed: {item.get('is_keyed', False)}")
        if item.get("indexing_return_type"):
            print(f"indexing_return_type: {item['indexing_return_type']}")

    summarize_group("Members", item.get("members", []), lambda x: f"{x.get('name')}: {x.get('type', 'Variant')}", args.limit)
    summarize_group("Properties", item.get("properties", []), lambda x: f"{x.get('name')}: {x.get('type', 'Variant')}", args.limit)
    summarize_group("Methods", item.get("methods", []), format_method, args.limit)
    summarize_group("Signals", item.get("signals", []), lambda x: x.get("name", "<unnamed>"), args.limit)
    summarize_group("Constants", item.get("constants", []), lambda x: f"{x.get('name')} = {x.get('value')}", args.limit)
    summarize_group("Enums", item.get("enums", []), lambda x: x.get("name", "<unnamed>"), args.limit)
    summarize_group("Operators", item.get("operators", []), lambda x: f"{x.get('name')}({x.get('right_type', '')}) -> {x.get('return_type', 'Variant')}", args.limit)
    summarize_group("Constructors", item.get("constructors", []), lambda x: f"index {x.get('index')}", args.limit)


def command_method(args: argparse.Namespace) -> None:
    api = load_api(args.api)
    found = find_type(api, args.class_name, args.case_sensitive)
    if not found:
        raise SystemExit(f"Class or builtin class not found: {args.class_name}")
    _, item = found
    methods = [
        method
        for method in item.get("methods", [])
        if matches(method.get("name"), args.method_name, args.case_sensitive, exact=not args.partial)
    ]
    if not methods:
        raise SystemExit(f"Method not found: {item.get('name')}.{args.method_name}")
    if args.json:
        print_json(methods)
        return
    for method in methods:
        print(f"{item.get('name')}.{format_method(method)}")
        if args.raw:
            print_json(method)


def add_result(results: list[JsonObject], kind: str, path: str, detail: str = "") -> None:
    results.append({"kind": kind, "path": path, "detail": detail})


def command_search(args: argparse.Namespace) -> None:
    api = load_api(args.api)
    results: list[JsonObject] = []

    kind_by_section = {
        "classes": "class",
        "builtin_classes": "builtin_class",
    }
    for section in ("classes", "builtin_classes"):
        for cls in section_items(api, section):
            class_name = cls.get("name", "")
            if matches(class_name, args.term, args.case_sensitive):
                add_result(results, kind_by_section[section], class_name)
            for method in cls.get("methods", []):
                method_name = method.get("name", "")
                if matches(method_name, args.term, args.case_sensitive):
                    add_result(results, "method", f"{class_name}.{method_name}", format_method(method))
            for prop in cls.get("properties", []):
                prop_name = prop.get("name", "")
                if matches(prop_name, args.term, args.case_sensitive):
                    add_result(results, "property", f"{class_name}.{prop_name}", prop.get("type", "Variant"))
            for signal in cls.get("signals", []):
                signal_name = signal.get("name", "")
                if matches(signal_name, args.term, args.case_sensitive):
                    add_result(results, "signal", f"{class_name}.{signal_name}")
            for const in cls.get("constants", []):
                const_name = const.get("name", "")
                if matches(const_name, args.term, args.case_sensitive):
                    add_result(results, "constant", f"{class_name}.{const_name}", str(const.get("value", "")))
            for enum in cls.get("enums", []):
                enum_name = enum.get("name", "")
                if matches(enum_name, args.term, args.case_sensitive):
                    add_result(results, "enum", f"{class_name}.{enum_name}")
                for value in enum.get("values", []):
                    value_name = value.get("name", "")
                    if matches(value_name, args.term, args.case_sensitive):
                        add_result(results, "enum_value", f"{class_name}.{enum_name}.{value_name}", str(value.get("value", "")))

    for func in section_items(api, "utility_functions"):
        name = func.get("name", "")
        if matches(name, args.term, args.case_sensitive):
            add_result(results, "utility_function", name, format_method(func))

    for singleton in section_items(api, "singletons"):
        name = singleton.get("name", "")
        typ = singleton.get("type", "")
        if matches(name, args.term, args.case_sensitive) or matches(typ, args.term, args.case_sensitive):
            add_result(results, "singleton", name, typ)

    for enum in section_items(api, "global_enums"):
        enum_name = enum.get("name", "")
        if matches(enum_name, args.term, args.case_sensitive):
            add_result(results, "global_enum", enum_name)
        for value in enum.get("values", []):
            value_name = value.get("name", "")
            if matches(value_name, args.term, args.case_sensitive):
                add_result(results, "global_enum_value", f"{enum_name}.{value_name}", str(value.get("value", "")))

    for native in section_items(api, "native_structures"):
        name = native.get("name", "")
        if matches(name, args.term, args.case_sensitive):
            add_result(results, "native_structure", name, native.get("format", ""))

    results.sort(key=lambda row: (row["kind"], row["path"].lower()))
    if args.json:
        print_json(results[: args.limit])
        return
    for row in results[: args.limit]:
        detail = f" - {row['detail']}" if row["detail"] else ""
        print(f"{row['kind']}: {row['path']}{detail}")
    if len(results) > args.limit:
        print(f"... {len(results) - args.limit} more")


def candidate_godot_bins() -> list[Path]:
    candidates: list[Path] = []
    env_bin = os.environ.get("GODOT_BIN")
    if env_bin:
        candidates.append(Path(env_bin))

    for name in ("godot", "godot4", "godot.exe", "Godot.exe"):
        found = shutil.which(name)
        if found:
            candidates.append(Path(found))

    if os.name == "nt":
        roots = []
        for env_name in ("LOCALAPPDATA", "ProgramFiles"):
            value = os.environ.get(env_name)
            if value:
                roots.append(Path(value))
        for root in roots:
            for subdir in ("CodexGodot", "Godot"):
                base = root / subdir
                if base.exists():
                    candidates.extend(base.rglob("Godot*_console.exe"))
                    candidates.extend(base.rglob("Godot*.exe"))

    unique: dict[str, Path] = {}
    for candidate in candidates:
        unique[str(candidate)] = candidate
    return sorted(unique.values(), key=lambda p: (0 if "console" in p.name.lower() else 1, str(p)), reverse=False)


def resolve_godot(path: str | None) -> Path:
    if path:
        resolved = Path(path).expanduser().resolve()
        if not resolved.exists():
            raise SystemExit(f"Godot executable not found: {resolved}")
        return resolved
    for candidate in candidate_godot_bins():
        if candidate.exists():
            return candidate.resolve()
    raise SystemExit("Godot executable not found. Pass --godot or set GODOT_BIN.")


def command_export(args: argparse.Namespace) -> None:
    godot = resolve_godot(args.godot)
    output = (args.output or default_api_output_path()).resolve()
    if output.exists() and not args.force:
        raise SystemExit(f"Refusing to overwrite existing file without --force: {output}")
    output.parent.mkdir(parents=True, exist_ok=True)

    dump_flag = "--dump-extension-api-with-docs" if args.with_docs else "--dump-extension-api"
    with tempfile.TemporaryDirectory(prefix="godot-api-dump-") as tmp:
        workdir = Path(tmp)
        command = [str(godot), "--headless"]
        if args.project:
            command.extend(["--path", str(args.project.resolve())])
        command.append(dump_flag)
        completed = subprocess.run(command, cwd=workdir, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if completed.returncode != 0:
            print(completed.stdout, file=sys.stderr)
            raise SystemExit(completed.returncode)
        dumped = workdir / "extension_api.json"
        if not dumped.exists():
            print(completed.stdout, file=sys.stderr)
            raise SystemExit("Godot did not produce extension_api.json")
        shutil.copyfile(dumped, output)
    api = load_api(output)
    print(f"Exported {version_label(api)} to {output}")


def command_validate(args: argparse.Namespace) -> None:
    godot = resolve_godot(args.godot)
    api_path = resolve_api_path(args.api)
    command = [str(godot), "--headless", "--validate-extension-api", str(api_path)]
    completed = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(completed.stdout.rstrip())
    raise SystemExit(completed.returncode)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Export and query Godot extension_api.json dumps.")
    parser.set_defaults(func=None)
    parser.add_argument("--api", type=Path, help="Path to extension_api.json. Defaults to the first discovered API dump.")

    subparsers = parser.add_subparsers(dest="command", required=True)

    summary = subparsers.add_parser("summary", help="Print API version and section counts.")
    summary.add_argument("--json", action="store_true", help="Emit JSON.")
    summary.set_defaults(func=command_summary)

    list_cmd = subparsers.add_parser("list", help="List API item names by section.")
    list_cmd.add_argument("section", choices=("classes", "builtin-classes", "singletons", "utility-functions", "global-enums", "native-structures", "all"))
    list_cmd.add_argument("--filter", help="Substring filter for names.")
    list_cmd.add_argument("--limit", type=int, default=200)
    list_cmd.add_argument("--case-sensitive", action="store_true")
    list_cmd.add_argument("--json", action="store_true")
    list_cmd.set_defaults(func=command_list)

    class_cmd = subparsers.add_parser("class", help="Show a class or builtin class overview.")
    class_cmd.add_argument("name")
    class_cmd.add_argument("--limit", type=int, default=40)
    class_cmd.add_argument("--case-sensitive", action="store_true")
    class_cmd.add_argument("--json", action="store_true")
    class_cmd.set_defaults(func=command_class)

    method = subparsers.add_parser("method", help="Show method signatures for a class or builtin class.")
    method.add_argument("class_name")
    method.add_argument("method_name")
    method.add_argument("--partial", action="store_true", help="Use substring matching for the method name.")
    method.add_argument("--raw", action="store_true", help="Also print the raw JSON for each method.")
    method.add_argument("--case-sensitive", action="store_true")
    method.add_argument("--json", action="store_true")
    method.set_defaults(func=command_method)

    search = subparsers.add_parser("search", help="Search API names across all major sections.")
    search.add_argument("term")
    search.add_argument("--limit", type=int, default=80)
    search.add_argument("--case-sensitive", action="store_true")
    search.add_argument("--json", action="store_true")
    search.set_defaults(func=command_search)

    export = subparsers.add_parser("export", help="Export extension_api.json from a local Godot executable.")
    export.add_argument("--godot", help="Path to the Godot executable. Defaults to GODOT_BIN, PATH, or common Windows locations.")
    export.add_argument("--output", type=Path, help="Output JSON path. Defaults to the first discovered API dump, or the skill-adjacent dump path.")
    export.add_argument("--project", type=Path, help="Optional Godot project directory for --path.")
    export.add_argument("--with-docs", action="store_true", help="Use --dump-extension-api-with-docs.")
    export.add_argument("--force", action="store_true", help="Overwrite an existing output file.")
    export.set_defaults(func=command_export)

    validate = subparsers.add_parser("validate", help="Validate an API dump with Godot --validate-extension-api.")
    validate.add_argument("--godot", help="Path to the Godot executable. Defaults to GODOT_BIN, PATH, or common Windows locations.")
    validate.set_defaults(func=command_validate)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    args.func(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
