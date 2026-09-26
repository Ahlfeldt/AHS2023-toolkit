"""Small Pyodide data service for the AHS / LSE-REEF atlas."""

from __future__ import annotations

import csv
import gzip
import io
import json
from collections import defaultdict

from pyodide.http import pyfetch


DATA = {}


def _number(value: str, integer: bool = False):
    if value == "" or value.lower() in {"nan", "<na>"}:
        return None
    return int(float(value)) if integer else float(value)


async def load_data(urls_json: str) -> str:
    for key, url in json.loads(urls_json).items():
        response = await pyfetch(url)
        response.raise_for_status()
        raw = gzip.decompress(await response.bytes()).decode("utf-8")
        by_area = defaultdict(list)
        for row in csv.DictReader(io.StringIO(raw)):
            by_area[row["area"]].append({
                "name": row["name"], "year": _number(row["year"], True),
                "value": _number(row["value"]), "se": _number(row["se"]),
                "obs": _number(row["obs"], True), "radius": _number(row["radius"]),
            })
        DATA[key] = dict(by_area)
    return json.dumps({"products": len(DATA)})


def snapshot(product: str, year: int) -> str:
    result = {}
    for area, rows in DATA[product].items():
        row = next((item for item in rows if item["year"] == year), None)
        if row and row["value"] is not None:
            result[area] = row["value"]
    return json.dumps(result, separators=(",", ":"))


def history(product: str, area: str) -> str:
    return json.dumps(DATA.get(product, {}).get(area, []), separators=(",", ":"))


def available_years(product: str) -> str:
    years = sorted({row["year"] for rows in DATA[product].values() for row in rows if row["value"] is not None})
    return json.dumps(years)
