# AHS commune index for France

This folder contains the public 2026 release of the French AHS residential
purchase-price index used by the combined browser atlas.

- Coverage: 33,183 communes and municipal arrondissements, 2014–2025
- Geography: metropolitan France and Corsica
- Spatial identifiers: text-safe `FR`-prefixed INSEE codes
- Source transactions: Cerema DVF+ 2026-1
- Estimator: AHS residential purchase-price index

`Data` contains a long-format CSV with price estimates, standard errors,
transaction counts, and estimation radii. `Shapefile` contains matching public
commune boundaries with area identifiers and commune names. `Boundary` contains
the separate metropolitan-France/Corsica national outline used by the atlas.
That outline is derived from the public-domain Natural Earth 1:10m Admin 0
Countries release, version 5.1.1. The public commune geometry is simplified to
reduce download and repository size; the full-resolution authoritative
GeoPackage remains in the private research workspace.

Paris, Lyon, and Marseille are represented by their official municipal
arrondissements. The source transaction microdata are confidential working data
and are not distributed in this repository.

The deployment files in `WEBTOOL/data` are generated from this folder by
`WEBTOOL/build_data.py`.
