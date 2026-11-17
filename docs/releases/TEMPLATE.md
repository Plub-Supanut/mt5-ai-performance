# Release vX.Y.Z — YYYY-MM-DD

> Copy this file to `docs/releases/vX.Y.Z.md` and fill every section.
> Keep the language plain and factual: what changed, who it affects, how to use/upgrade, known issues.

## Summary

One or two sentences describing the release and why it exists.

**Version type:** patch / minor / major (see [SemVer](https://semver.org/))

## What changed

### Added
- ...

### Changed
- ...

### Fixed
- ...

### Security
- ...

## Who it affects

- **Dashboard visitors:** ...
- **Operators of the bot / sync pipeline:** ...
- **Anyone consuming `data.json`:** ...

## How to use / upgrade

1. Open the live dashboard: <https://plub-supanut.github.io/mt5-ai-performance/>
2. Or download the artifact attached to this release and serve it locally:
   ```bash
   python -m http.server 8080
   ```
3. No migration is required unless this section says otherwise.

## Known issues

- Data is a periodic snapshot (roughly every 15 minutes); live MT5 positions and floating P&L may lag by up to one sync interval.
- The dashboard UI is primarily Thai with English metric labels.
- Opening `index.html` as a `file://` URL does not load data; use a static server.

## Verification

- [ ] CI green on `main`
- [ ] `data.json` still parses and contains `generated_at`, `account`, `stats_all`, `equity_snapshots`, `trades`
- [ ] Live page returns HTTP 200
- [ ] No secrets, account numbers or credentials added

## Artifact

- `mt5-ai-performance-vX.Y.Z.zip` — standalone dashboard (`index.html`, `data.json`, `README.md`, `LICENSE`)
