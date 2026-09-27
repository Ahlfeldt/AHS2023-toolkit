# AHS / LSE-REEF Property Price Atlas

This static browser viewer combines the German AHS postcode indices with the
LSE-REEF lower-layer super output area index for England and Wales. Python runs
locally in the visitor's browser through Pyodide; there is no application server
and no collection of user data.

The controls are organised by market, followed by the countries for which that
market is available. One or both countries can be shown on a single European
map. Values can be displayed in euros or pounds; the viewer retrieves the latest
ECB reference rate through the Frankfurter API and shows its date. A stored rate
is used only if the live service cannot be reached.

## Rebuild the web data

From the repository root, run:

```powershell
python WEBTOOL/build_data.py
```

The build reads the authoritative 2026 AHS outputs and German shapes already in
the repository, plus the official LSE-REEF data and shapefile under
`APPLICATIONS/ENGLAND_WALES`. It writes compressed browser assets to
`WEBTOOL/data`.

## Test locally

Serve the directory over HTTP and open its root page. Opening `index.html`
directly will not work because the browser must fetch compressed assets.

## Sources

- Germany: Ahlfeldt, Heblich and Seidel (2023), *Micro-geographic property price
  and rent indices*.
- England and Wales: Ahlfeldt, Carozzi and Makovsky (2023), *A micro-geographic
  house price index for England and Wales*.
- Basemap: OpenStreetMap contributors.
