"""Build compact browser assets for the combined AHS / LSE-REEF atlas."""

from __future__ import annotations

import gzip
import json
from pathlib import Path

import geopandas as gpd
import pandas as pd
import shapely


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "WEBTOOL" / "data"
GERMAN_DATA = ROOT / "APPLICATIONS" / "DATA" / "OUTPUT" / "2026"
GERMAN_SHAPES = ROOT / "APPLICATIONS" / "SHAPES"
REEF = ROOT / "APPLICATIONS" / "ENGLAND_WALES"
FRANCE = ROOT / "APPLICATIONS" / "FRANCE"

STATE_NAMES = {
    "01": "Schleswig-Holstein", "02": "Hamburg", "03": "Lower Saxony",
    "04": "Bremen", "05": "North Rhine-Westphalia", "06": "Hesse",
    "07": "Rhineland-Palatinate", "08": "Baden-Württemberg", "09": "Bavaria",
    "10": "Saarland", "11": "Berlin", "12": "Brandenburg",
    "13": "Mecklenburg-Vorpommern", "14": "Saxony", "15": "Saxony-Anhalt",
    "16": "Thuringia",
}

PRODUCTS = {
    "de_purchase": {
        "country": "de", "label": "Residential purchase price", "unit": "€ per m²", "currency": "EUR",
        "source": GERMAN_DATA / "AHS-Index-res-PURCH-PLZ-2026" / "AHS-Index-res-PURCH-PLZ-2026-long.csv",
    },
    "de_rent": {
        "country": "de", "label": "Residential rent", "unit": "€ per m²/month", "currency": "EUR",
        "source": GERMAN_DATA / "AHS-Index-res-RENT-PLZ-2026" / "AHS-Index-res-RENT-PLZ-2026-long.csv",
    },
    "gb_purchase": {
        "country": "gb", "label": "Residential purchase price", "unit": "£ per m²", "currency": "GBP",
        "source": REEF / "Data" / "LSE-REEF-INDEX-2020.csv",
    },
    "fr_purchase": {
        "country": "fr", "label": "Residential purchase price", "unit": "€ per m²", "currency": "EUR",
        "source": FRANCE / "Data" / "AHS-FRANCE-COMMUNE-2026.csv",
    },
}


def write_geojson(frame: gpd.GeoDataFrame, name: str, streaming: bool = False) -> None:
    frame = frame.to_crs(4326)
    frame["geometry"] = shapely.set_precision(frame.geometry.array, grid_size=0.00001)
    if streaming:
        with gzip.open(OUTPUT / name, "wt", encoding="utf-8") as stream:
            stream.write('{"type":"FeatureCollection","features":[')
            for index, feature in enumerate(frame.iterfeatures(drop_id=True, na="null")):
                if index:
                    stream.write(",")
                json.dump(feature, stream, ensure_ascii=False, separators=(",", ":"))
            stream.write("]}")
        return
    with gzip.open(OUTPUT / name, "wt", encoding="utf-8") as stream:
        stream.write(frame.to_json(drop_id=True, separators=(",", ":")))


def build_geographies() -> dict[str, int]:
    postcodes = gpd.read_file(GERMAN_SHAPES / "POSTCODES" / "postcode_clean_final.shp")[["ZIP_CODE", "geometry"]]
    postcodes["area"] = postcodes["ZIP_CODE"].astype(str).str.zfill(5)
    write_geojson(postcodes[["area", "geometry"]], "de_areas.geojson.gz")

    counties = gpd.read_file(GERMAN_SHAPES / "COUNTIES" / "VG250_KRS_clean_final.shp")[["SN_L", "geometry"]]
    states = counties.dissolve(by="SN_L", as_index=False)
    states["geometry"] = states.geometry.simplify(25, preserve_topology=True)
    states["name"] = states["SN_L"].map(STATE_NAMES)
    states = states.rename(columns={"SN_L": "area"})
    write_geojson(states[["area", "name", "geometry"]], "de_boundaries.geojson.gz")

    reef_shape = REEF / "Shapefile" / "LSE-REEF-INDEX-2020.shp"
    lsoas = gpd.read_file(reef_shape)[["target_id", "LSOA11NM", "geometry"]]
    lsoas = lsoas.rename(columns={"target_id": "area", "LSOA11NM": "name"})
    write_geojson(lsoas, "gb_areas.geojson.gz")

    # A single coastline outline gives England & Wales a clear national edge.
    outline = lsoas[["geometry"]].dissolve().reset_index(drop=True)
    outline["area"] = "EW"
    outline["name"] = "England & Wales"
    write_geojson(outline[["area", "name", "geometry"]], "gb_boundaries.geojson.gz")

    france_shape = FRANCE / "Shapefile" / "AHS-FRANCE-COMMUNE-2026.shp"
    communes = gpd.read_file(france_shape)[["area", "name", "geometry"]]
    communes["area"] = communes["area"].astype(str)
    write_geojson(communes, "fr_areas.geojson.gz", streaming=True)

    france_outline = gpd.read_file(
        FRANCE / "Boundary" / "AHS-FRANCE-BOUNDARY-2026.shp"
    )[["area", "name", "geometry"]]
    write_geojson(france_outline[["area", "name", "geometry"]], "fr_boundaries.geojson.gz")
    return {"de": len(postcodes), "gb": len(lsoas), "fr": len(communes)}


def build_german_product(key: str, config: dict[str, object]) -> dict[str, object]:
    frame = pd.read_csv(config["source"], usecols=["postcode_id", "year", "price_qm", "price_qm_se", "Obs", "Radius"])
    frame["area"] = frame["postcode_id"].map(lambda value: f"{int(float(value)):05d}")
    frame = frame.rename(columns={"price_qm": "value", "price_qm_se": "se", "Obs": "obs", "Radius": "radius"})
    frame["name"] = ""
    frame = frame[["area", "name", "year", "value", "se", "obs", "radius"]].sort_values(["area", "year"])
    return write_product(key, config, frame)


def build_reef_product(key: str, config: dict[str, object]) -> dict[str, object]:
    wide = pd.read_csv(config["source"])
    names = gpd.read_file(REEF / "Shapefile" / "LSE-REEF-INDEX-2020.shp")[["target_id", "LSOA11NM"]]
    wide = wide.merge(names, on="target_id", how="left")
    rows = []
    for year in range(2010, 2021):
        part = wide[["target_id", "LSOA11NM", f"p_{year}", f"se_{year}"]].copy()
        part.columns = ["area", "name", "value", "se"]
        part["year"] = year
        part["obs"] = pd.NA
        part["radius"] = pd.NA
        rows.append(part)
    frame = pd.concat(rows, ignore_index=True)[["area", "name", "year", "value", "se", "obs", "radius"]]
    return write_product(key, config, frame.sort_values(["area", "year"]))


def build_standard_product(key: str, config: dict[str, object]) -> dict[str, object]:
    columns = ["area", "name", "year", "value", "se", "obs", "radius"]
    frame = pd.read_csv(config["source"], dtype={"area": str}, usecols=columns)
    return write_product(key, config, frame.sort_values(["area", "year"]))


def write_product(key: str, config: dict[str, object], frame: pd.DataFrame) -> dict[str, object]:
    with gzip.open(OUTPUT / f"{key}.csv.gz", "wt", encoding="utf-8", newline="") as stream:
        frame.to_csv(stream, index=False, float_format="%.6g")
    valid = frame["value"].notna()
    return {
        "country": config["country"], "label": config["label"], "unit": config["unit"],
        "currency": config["currency"],
        "file": f"data/{key}.csv.gz", "first_year": int(frame.loc[valid, "year"].min()),
        "last_year": int(frame.loc[valid, "year"].max()), "observations": int(valid.sum()),
    }


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    counts = build_geographies()
    products = {}
    for key, config in PRODUCTS.items():
        if key.startswith("gb_"):
            products[key] = build_reef_product(key, config)
        elif key.startswith("fr_"):
            products[key] = build_standard_product(key, config)
        else:
            products[key] = build_german_product(key, config)
    payload = {
        "countries": {
            "de": {"label": "Germany", "area_label": "Postcode", "search_placeholder": "e.g. 10117", "geography": "data/de_areas.geojson.gz", "boundaries": "data/de_boundaries.geojson.gz", "count": counts["de"]},
            "gb": {"label": "England & Wales", "area_label": "LSOA", "search_placeholder": "e.g. E01000001", "geography": "data/gb_areas.geojson.gz", "boundaries": "data/gb_boundaries.geojson.gz", "count": counts["gb"]},
            "fr": {"label": "France", "area_label": "Commune", "search_placeholder": "e.g. FR75101", "geography": "data/fr_areas.geojson.gz", "boundaries": "data/fr_boundaries.geojson.gz", "count": counts["fr"]},
        },
        "products": products,
    }
    (OUTPUT / "metadata.json").write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
