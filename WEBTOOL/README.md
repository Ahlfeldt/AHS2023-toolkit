# AHS / LSE-REEF Property Price Atlas

This static browser viewer combines the German AHS postcode indices, the French
AHS commune index, and the LSE-REEF lower-layer super output area index for
England and Wales. Python runs
locally in the visitor's browser through Pyodide; there is no application server
and no collection of user data.

## Citation requirement

Use of the AHS indices is conditional on citing Ahlfeldt, Heblich and Seidel
(2023), *Micro-geographic property price and rent indices*, Regional Science
and Urban Economics 98.
https://doi.org/10.1016/j.regsciurbeco.2022.103836

Users of the England and Wales index should additionally cite Ahlfeldt, Carozzi
and Makovsky (2023), *A micro-geographic house price index for England and
Wales*.

The controls are organised by market, followed by the countries for which that
market is available. One or more countries can be shown on a single European
map. Values can be displayed in euros or pounds; the viewer retrieves the latest
ECB reference rate through the Frankfurter API and shows its date. A stored rate
is used only if the live service cannot be reached.

## Rebuild the web data

From the repository root, run:

```powershell
python WEBTOOL/build_data.py
```

The build reads the authoritative 2026 German AHS outputs and shapes, the public
French index and commune geography under `APPLICATIONS/FRANCE`, plus the
official LSE-REEF data and shapefile under `APPLICATIONS/ENGLAND_WALES`. It
writes compressed browser assets to `WEBTOOL/data`.

## Test locally

Serve the directory over HTTP and open its root page. Opening `index.html`
directly will not work because the browser must fetch compressed assets.

## Sources

- Germany: Ahlfeldt, Heblich and Seidel (2023), *Micro-geographic property price
  and rent indices*.
- France: AHS commune purchase-price estimates for 2014–2025, based on DVF+.
- England and Wales: Ahlfeldt, Carozzi and Makovsky (2023), *A micro-geographic
  house price index for England and Wales*.
- Basemap: OpenStreetMap contributors.
