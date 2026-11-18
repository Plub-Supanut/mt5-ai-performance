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

## [1.1.0] - 2026-11-18

### Added
- **THESIS-1 thesis display** shared by all four AI surfaces (open position, pending order, closed-trade drawer, journal/lessons). One parser (`parseThesis`) segments every reason losslessly, labels each clause from a closed 14-label enum (alignment, trigger, context, stop, target, management, risk, rationale, outcome, cause, rule, boilerplate, note, unparsed) and extracts a best-effort fact mirror (bias, timeframes/alignment, SL/TP with reference kind and price, R:R as written, ADR flag, RSI, session, risk budget, P&L, symbols, sides).
- **Shared thesis component**: timeframe/bias chips, a labelled SL / TP / R:R fact row, an ordered clause list with semantic labels, Thai lesson prose with emphasised numbers, and a keyboard-operable **RAW** disclosure for the verbatim text.
- **Machine-readable mirror** on every entry: `data-thesis-json` (`THESIS-1` object), `data-thesis-version`, `data-thesis-kind`, `data-thesis-mode`, `data-thesis-ok` and `data-thesis-context`, plus a visually hidden heading — the same information for humans and agents.
- **Contract and proposal docs**: `docs/thesis-contract.md` (normative grammar/fields/render rules) and `docs/thesis-prompt-addendum.md` (proposal only, not applied to the bot prompt).
- Release notes for `v1.1.0`.

### Changed
- Pending orders keep the computed R:R from trigger/SL/TP as the authoritative number; the thesis fact row shows the sentence's R:R labelled **as written** when both exist.
- Numbers in clause text render exactly as written; formatted values only appear in the separate fact row.
- Trade detail drawer now renders the entry thesis and the linked lesson through the same component instead of two raw paragraphs.
- README documents the feature, keyboard-operable disclosures, the new docs and the machine mirror.

### Fixed
- Long Thai lessons and dense English theses no longer render as a wall of text or break the card layout.
- Missing (`null`) thesis text now degrades cleanly: legacy trades keep the neutral absence message; unparseable text shows escaped plain text; `AI adjust` / `AI cancel` render as muted boilerplate; nothing shows `undefined`, `null` or `NaN`.

### Accessibility
- Thesis and raw disclosures are native `<details>` with a visible brass focus ring.
- Facts use `<dl>/<dt>/<dd>`, clauses use `<ol>/<li>`, entries carry an `<h3>` (visually hidden where a visible title already exists).
- No new motion; `prefers-reduced-motion` remains respected.

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

[Unreleased]: https://github.com/Plub-Supanut/mt5-ai-performance/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/Plub-Supanut/mt5-ai-performance/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Plub-Supanut/mt5-ai-performance/releases/tag/v1.0.0
