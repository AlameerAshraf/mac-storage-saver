#!/usr/bin/env python3
"""Render a mac-storage-saver HTML report from a JSON data file.

Usage:
  python3 -I render_report.py data.json report.html            # standalone page
  python3 -I render_report.py data.json report.html --artifact # no <!doctype>/<html> wrapper

The data format is described in references/report-data.md, and
templates/example-data.json is a complete example.
"""
import argparse
import html
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
DEFAULT_TEMPLATE = HERE.parent / "templates" / "report.html"
TIERS = {"safe", "re", "call"}
RANK_TIERS = TIERS | {"keep", "stuck"}


def fail(msg):
    print(f"render_report: {msg}", file=sys.stderr)
    sys.exit(1)


def validate(data):
    if not isinstance(data, dict):
        fail("data must be a JSON object")
    disk = data.get("disk")
    if not isinstance(disk, dict):
        fail('missing "disk" object')
    for key in ("total_gb", "free_gb"):
        if not isinstance(disk.get(key), (int, float)):
            fail(f'"disk.{key}" must be a number')
    seen = set()
    for i, item in enumerate(data.get("items", [])):
        where = f"items[{i}]"
        if item.get("tier") not in TIERS:
            fail(f'{where}.tier must be one of {sorted(TIERS)}')
        if not item.get("name"):
            fail(f"{where}.name is required")
        if not isinstance(item.get("gb"), (int, float)):
            fail(f"{where}.gb must be a number")
        key = item.get("id")
        if key:
            if key in seen:
                fail(f'duplicate item id "{key}"')
            seen.add(key)
    for i, row in enumerate(data.get("rank", [])):
        if row.get("tier", "keep") not in RANK_TIERS:
            fail(f"rank[{i}].tier must be one of {sorted(RANK_TIERS)}")
    for name in ("done", "stuck"):
        for i, row in enumerate(data.get(name, [])):
            if not row.get("name") or not isinstance(row.get("gb"), (int, float)):
                fail(f"{name}[{i}] needs a name and a numeric gb")


def between(text, start, end):
    a, b = text.find(start), text.find(end)
    if a < 0 or b < 0 or b < a:
        fail(f"template is missing the {start} / {end} markers")
    return text[a + len(start):b]


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("data", help="report data JSON file")
    ap.add_argument("out", help="HTML file to write")
    ap.add_argument("--template", default=str(DEFAULT_TEMPLATE), help="template path")
    ap.add_argument("--artifact", action="store_true", help="omit the document wrapper")
    args = ap.parse_args()

    try:
        data = json.loads(pathlib.Path(args.data).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"can't read {args.data}: {exc}")
    validate(data)

    template = pathlib.Path(args.template).read_text(encoding="utf-8")
    for marker in ("__REPORT_TITLE__", "__REPORT_DATA__"):
        if template.count(marker) != 1:
            fail(f"template must contain {marker} exactly once")

    payload = (json.dumps(data, ensure_ascii=False)
               .replace("&", "\\u0026").replace("<", "\\u003c").replace(">", "\\u003e"))
    title = html.escape(str(data.get("title") or "Mac Storage Audit"))
    page = template.replace("__REPORT_TITLE__", title).replace("__REPORT_DATA__", payload)

    if args.artifact:
        page = (between(page, "<!--MSS:HEAD-START-->", "<!--MSS:HEAD-END-->").strip() + "\n\n" +
                between(page, "<!--MSS:BODY-START-->", "<!--MSS:BODY-END-->").strip() + "\n")

    out = pathlib.Path(args.out)
    out.write_text(page, encoding="utf-8")
    print(f"Wrote {out} ({len(data.get('items', []))} items to approve, {len(data.get('done', []))} cleaned)")


if __name__ == "__main__":
    main()
