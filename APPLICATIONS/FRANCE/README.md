# AHS commune index for France

This folder contains the public 2026 release of the French AHS residential
purchase-price index used by the combined browser atlas.

- Coverage: 33,183 communes and municipal arrondissements, 2014–2025
- Geography: metropolitan France and Corsica
- Spatial identifiers: text-safe `FR`-prefixed INSEE codes
- Source transactions: Cerema DVF+ 2026-1
- Estimator: AHS residential purchase-price index

## Citation requirement

Use of this index is conditional on citing Ahlfeldt, Heblich and Seidel (2023),
*Micro-geographic property price and rent indices*, Regional Science and Urban
Economics 98. https://doi.org/10.1016/j.regsciurbeco.2022.103836

## Files available from GitHub

- [`Data/AHS-FRANCE-COMMUNE-2026.csv`](Data/AHS-FRANCE-COMMUNE-2026.csv) is the
  long-format index. It reports the estimated price per square metre, standard
  error, transaction count, and estimation radius for every area-year.
- [`Shapefile`](Shapefile) contains the matching public commune and municipal-
  arrondissement shapefile, including the text-safe area identifier and commune
  name.
- [`Boundary`](Boundary) contains the separate metropolitan-France/Corsica
  national outline used by the atlas. It is derived from the public-domain
  [Natural Earth 1:10m Admin 0 Countries](https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-admin-0-countries/)
  release, version 5.1.1.

The commune geometry distributed here is topology-preserving but simplified to
keep the repository and browser download manageable. The full-detail source
geography can be downloaded from IGN's
[ADMIN EXPRESS catalogue](https://cartes.gouv.fr/rechercher-une-donnee/dataset/IGNF_ADMIN-EXPRESS).

## Construction of the index

The estimates use the Cerema **DVF+ 2026-1** release. We retained geolocated
residential purchase transactions in metropolitan France and Corsica for
2014–2025, restricted coordinates to the extent of the covered IGN geography,
and excluded 322 coordinate outliers. The resulting estimation input contains
9,582,931 sales.

The target geography combines standard INSEE communes with the official
municipal arrondissements of Paris, Lyon, and Marseille, producing 33,183
covered areas. Area identifiers are stored as text with an `FR` prefix so that
leading zeroes and alphanumeric Corsican INSEE codes survive CSV and GIS joins.
The price levels and standard errors were estimated with the AHS methodology
described by Ahlfeldt, Heblich and Seidel (2023), *Micro-geographic property
price and rent indices*,
[Regional Science and Urban Economics 98](https://doi.org/10.1016/j.regsciurbeco.2022.103836).

The raw DVF+ files are freely downloadable from the official
[Cerema Datafoncier DVF+ page](https://datafoncier.cerema.fr/donnees/autres-donnees-foncieres/dvfplus-open-data)
or the corresponding
[data.gouv.fr dataset](https://www.data.gouv.fr/datasets/dvf-open-data).

The prepared estimation microdata are not duplicated in this repository; users
can reconstruct them from the open DVF+ source files above.

The deployment files in `WEBTOOL/data` are generated from this folder by
`WEBTOOL/build_data.py`.
