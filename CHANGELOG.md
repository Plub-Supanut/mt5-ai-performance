# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Release notes for each version live in [`docs/releases/`](docs/releases/).

## [Unreleased]

### Planned
- Mobile layout refinements for the positions and ledger tables.
- Optional timeframe control for the equity curve.
- Documented data-freshness indicator on the dashboard footer.

## [1.0.0] - 2026-11-17

### Added
- Public single-file dashboard (`index.html`) reading `data.json`: capital horizon, core performance, cumulative P&L / equity / drawdown chart, symbol matrix, open positions, pending orders, closed-trade ledger, AI lessons and decision journal.
- Live GitHub Pages deployment at <https://plub-supanut.github.io/mt5-ai-performance/>.
- `schema.sql` documenting the SQLite history database used by the bot's private sync pipeline.
- README rewritten to the project-standard blueprint: banner, badges, quick links, overview, quick start, features, screenshots, controls, project structure, development, release policy, attribution/disclaimer and license.
- `assets/` with a dashboard screenshot, a README banner and a 1280×640 social preview.
- GitHub Actions CI validating `data.json` structure, static assets and obvious secret patterns on push and pull requests.
- Issue forms (bug report, data issue) and a pull request template with safety and disclaimer checks.
- `CHANGELOG.md`, release notes for `v1.0.0`, `.gitignore`, `.gitattributes`, `.editorconfig` and an explicit all-rights-reserved `LICENSE`.

### Changed
- Dashboard copy and README clarify that the data comes from one personal Exness USC Cent account and is auto-generated on a roughly 15-minute cycle.
- Repository metadata aligned with the Plub GitHub Project Standard (description, homepage, topics, merge settings, templates).

### Fixed
- Missing documentation for the data pipeline and release process.

### Security
- CI secret scan over all tracked files; no broker credentials, account numbers, logins or investor passwords are published.

[Unreleased]: https://github.com/Plub-Supanut/mt5-ai-performance/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Plub-Supanut/mt5-ai-performance/releases/tag/v1.0.0
