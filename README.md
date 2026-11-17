# MT5 AI Trader — Performance Database & Dashboard

Live performance tracker and SQLite historical database for the autonomous MT5 AI Trader (`Exness USC`, target `8,000 USC`).

## Live Dashboard
- **GitHub Pages**: https://plub-supanut.github.io/mt5-ai-performance/

## Architecture
- `performance.db` (local SQLite, see `schema.sql`): stores `equity_snapshots`, `trades`, `open_positions`, `pending_orders`, `lessons`, and `journal`.
- `mt5_perf_db.py`: syncs historical deals & live positions from MetaTrader 5 + `ai_journal.jsonl` + `lessons.jsonl`, and exports `data.json`.
- `index.html`: responsive dark-mode dashboard reading `data.json` (equity curve, symbol breakdown, open positions, closed trades, AI lessons, and decision journal).

## Auto-Sync
Every 15-minute `mt5_bridge.py snapshot` & `journal` cycle automatically updates `performance.db`, exports `data.json`, and pushes updates to GitHub.

Manual sync:
```bash
python C:/Users/Plubs/mt5_bot/mt5_bridge.py sync-db --push
```
