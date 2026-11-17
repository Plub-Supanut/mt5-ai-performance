-- MT5 AI Trader Performance Database Schema (SQLite)

CREATE TABLE IF NOT EXISTS equity_snapshots (
    ts TEXT PRIMARY KEY,
    balance_usc REAL NOT NULL,
    equity_usc REAL NOT NULL,
    margin_free_usc REAL,
    peak_equity_usc REAL,
    open_positions INTEGER DEFAULT 0,
    pending_orders INTEGER DEFAULT 0,
    open_risk_usc REAL DEFAULT 0.0,
    daily_pnl_pct REAL DEFAULT 0.0,
    status TEXT
);

CREATE TABLE IF NOT EXISTS trades (
    position_id INTEGER PRIMARY KEY,
    symbol TEXT NOT NULL,
    side TEXT NOT NULL,
    volume REAL NOT NULL,
    entry_price REAL,
    exit_price REAL,
    entry_ts INTEGER,
    exit_ts INTEGER,
    entry_time_utc TEXT,
    exit_time_utc TEXT,
    duration_min REAL,
    profit_usc REAL DEFAULT 0.0,
    swap_usc REAL DEFAULT 0.0,
    commission_usc REAL DEFAULT 0.0,
    net_profit_usc REAL NOT NULL,
    risk_usc REAL,
    r_mult REAL,
    outcome TEXT NOT NULL,
    exit_type TEXT NOT NULL,
    comment TEXT,
    original_sl REAL,
    original_tp REAL,
    entry_reason TEXT,
    updated_ts TEXT
);

CREATE TABLE IF NOT EXISTS open_positions (
    ticket INTEGER PRIMARY KEY,
    symbol TEXT NOT NULL,
    side TEXT NOT NULL,
    volume REAL NOT NULL,
    price_open REAL,
    price_current REAL,
    sl REAL,
    tp REAL,
    profit_usc REAL DEFAULT 0.0,
    risk_usc REAL DEFAULT 0.0,
    open_time_utc TEXT,
    reason TEXT,
    updated_ts TEXT
);

CREATE TABLE IF NOT EXISTS pending_orders (
    ticket INTEGER PRIMARY KEY,
    symbol TEXT NOT NULL,
    order_type TEXT NOT NULL,
    volume REAL NOT NULL,
    price_open REAL,
    sl REAL,
    tp REAL,
    setup_time_utc TEXT,
    reason TEXT,
    updated_ts TEXT
);

CREATE TABLE IF NOT EXISTS lessons (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ts TEXT NOT NULL,
    position_id INTEGER,
    symbol TEXT,
    side TEXT,
    outcome TEXT,
    exit_type TEXT,
    profit_usc REAL,
    tag TEXT,
    scope TEXT,
    lesson TEXT NOT NULL,
    UNIQUE(ts, position_id, tag)
);

CREATE TABLE IF NOT EXISTS journal (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ts TEXT NOT NULL,
    action TEXT NOT NULL,
    symbol TEXT,
    side TEXT,
    lot REAL,
    entry REAL,
    sl REAL,
    tp REAL,
    risk_usc REAL,
    ticket INTEGER,
    reason TEXT,
    summary TEXT,
    raw_json TEXT,
    UNIQUE(ts, action, ticket, summary)
);
