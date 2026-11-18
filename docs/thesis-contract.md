# Thesis display contract — `THESIS-1`

**Status:** agreed between the writer side (`thesis-author`) and the renderer (`thesis-ui`).
**Scope:** how every AI thesis string that HERMES publishes is turned into something orderly for humans
and parseable for machines, without ever changing what the bot wrote.
**Evidence snapshot:** `data.json` at `generated_at = 2026-11-18T13:04:45+07:00`.
**Version of this document:** 1.0 (`THESIS-1`).

> The live trading prompt is **not** changed by this work. Section 7 describes a *proposed* addendum,
> filed separately as [`thesis-prompt-addendum.md`](./thesis-prompt-addendum.md), and it is not applied.

The terms **MUST**, **MUST NOT**, **SHOULD** and **MAY** are used as in RFC 2119.

---

## 0. For the renderer, in one screen

1. One pure function, e.g. `parseThesis(raw, kind)` → one `Thesis` object (section 3). No network, no deps,
   no DOM access, safe to call in a loop for 69 strings on page load.
2. **`raw` is sacred.** It is copied into the object unchanged and is always renderable. Parsing is an
   *addition*, never a substitution.
3. Splitting happens at `;` and `,` **only outside parentheses**, and the separators are kept in the clause
   objects so that `clauses.map(c => c.text + c.sep).join("") === raw` byte-for-byte.
4. Each clause gets exactly one label from a closed enum (section 3.4). A clause the rules cannot classify is
   `NOTE` and is still shown verbatim — never dropped, never rewritten.
5. If anything is out of contract (newlines, `|`, > 1200 chars) the parser gives up and returns
   `parse.mode = "raw"`; the renderer then shows the escaped text and nothing else (section 3.7).
6. `facts` is a convenience mirror of numbers **found in the text**. It is never a place to supply a number the
   text did not state. A null field renders as absent, not as `—` invented content.
7. The RR the dashboard already computes from trigger/SL/TP for pending orders stays authoritative.
   `facts.rr` is only the RR **as written in the sentence**.

---

## 1. What the writer actually emits (measured, not assumed)

### 1.1 The four surfaces and their real payload

| Surface | `data.json` field | Rendering point (`index.html`) | Non-null | Length (chars) |
|---|---|---|---|---|
| Open position thesis | `open_positions[].reason` | `openCard` → "AI Entry Thesis" (~L3215) | 1 / 1 | 133 |
| Trap / pending thesis | `pending_orders[].reason` | `pendingCard` → "Trap Thesis" (~L3247) | 3 / 3 | 89–133 |
| Closed-trade thesis | `trades[].entry_reason` | `tradeDetailHtml` → "Entry Thesis" (~L3295) | 12 / 22 | 89–212 |
| Journal line | `journal[].summary`, `journal[].reason` | `journalRow` → `.log-text` (~L3485) | 15 + 16 / 40 | 9–282 |
| Lesson | `lessons[].lesson` | `lessonRow` (~L3507) and `tradeDetailHtml` | 22 / 22 | 145–316 |

Totals: **69 non-null text values**, 11 674 characters, median 165.
Of those, **16 thesis values** but only **15 distinct strings** (the open AUDUSDc `reason` is byte-identical to
trade #1's `entry_reason`). All **11 `journal.reason` values on `OPEN_LIMIT` / `OPEN_MARKET` rows are byte-identical
republishes** of those theses (verified pairwise), plus 5 ops reasons, 15 HOLD/TRADE summaries and 22 lessons.

The two grammars are genuinely different and the contract keeps them apart:

* **`kind: "thesis"`** — short, English, clause-separated. 27 values (16 unique + 11 journal republishes).
* **`kind: "journal"`** — HOLD/TRADE summaries and ops reasons. 20 values. Mostly prose, not clauses.
* **`kind: "lesson"`** — Thai (21/22) narrative, 40 sentences. 22 values.

### 1.2 Observed clause catalogue

Counts are clause occurrences over the 16 thesis values (56 clauses, 2–5 per thesis, mean 3.5).

| Clause type | Count | Verbatim examples |
|---|---|---|
| **Multi-timeframe alignment** | 16 (always the first clause) | `H4/H1/M15 BEAR aligned` · `H4/H1 BULL` · `H4/H1/M15/M5 BEAR aligned` · `Aligned H4/H1/M15 BEAR pullback SELL LIMIT into H1 EMA20/M15 EMA50 (3866)` |
| **Level / trigger** | 11 | `M15 swept H1 EMA20 (0.67413) & rejected bearish` · `M15 liquidity sweep low 1.99939 & reclaim above H1 EMA20/PDH` · `M15 09:30 swept H1 EMA20 (91.03) up to 91.219 and printed SWEEP_HIGH_REJECT, M15 09:45 lower high 90.99` · `M15 rejected EMA200 at 3889 and EMA20/50 at 3868.4 then broke 3861.14 support to 3858` · `M15 pullback rejected off EMA50 (27385.88) with bearish candle 01:45` |
| **Context (RSI / session)** | 2 | `H1 RSI 27.5 oversold bounce toward M15 EMA20/50 (107.35-107.43)` · `H1 RSI 23.2 oversold pullback into M15 swing high / today_open 90.40-90.49` |
| **SL rationale** | 13 | `SL at today_high (1.5x H1 ATR)` · `SL 107.62 above today_high 107.57 (2.7x M15 ATR)` · `SL 51130 above H1 EMA20 (2.1x M15 ATR)` · `SL 90.92 above M15 EMA50 (90.72) & today_high` · `SL below today_low/H1 EMA50` · `SL 27425 above swing high + ~1.3x M15 ATR` |
| **TP / RR** | 14 | `TP 0.6708 (2.0R, within ADR)` · `TP 107.00 (RR 1.58)` · `targeting PDL 89.70 (2.5R)` · `TP 89.65 above H4 sl20 89.564 (2.63R)` · `TP 27135 front-running H4 swing low 27127.9 (1.80R)` · `TP 50580 above PDL` |
| **Risk / units** (journal) | 7 | `risk 113.18/93.0 USC` · `open risk 90.71/94.08 USC` · `Remaining risk budget 41.34 USC (2 slots)` · `Risk 90.71/94.08 USC (4/4 positions)` |
| **Partial / free-roll** (journal) | 7 | `Auto Partial TP 50% at +1.00R` · `Hold AUDUSDc SELL 0.11 free-roll (+18.81 USC, SL 0.67352 -> TP 0.67080)` · `Free-Roll EURNZDc BUY (SL->1.9997)` |
| **No-trade rationale** (journal) | 12 | `Tokyo/Asia session mid-day lacks clean A+ market entry` · `no new A+ setup with low spread` · `avoid chasing oversold USD/Crypto/US30` · `holding without new entries due to risk/position cap and wide rollover spreads` |
| **Boilerplate / system** | 5 (3 + 2) | `AI adjust` · `AI cancel` · `AI cancel` — plus `Auto Partial TP 50% at +1.00R` and `… at +1.01R`, which are *system*-generated management, not AI prose |
| **Thai lesson narrative** | 40 | 4-sentence shape in practice: outcome (instrument/entry/SL/PnL) → what the market did → why it broke → the rule (see 1.5) |
| **Residual prose** (`NOTE`) | 7 journal, 0 thesis | `All 7 positions in profit (+46.96 USC total)` · `logged 2 lessons (BTCUSDc/UKOILc)` · `risk_guard active.` · `keep US30c SELL LIMIT @ 50960` |

**A clause can carry two roles.** `H4/H1/M15 BEAR aligned pullback to M15 EMA20/50 below H1 EMA20` is both
alignment and trigger. The label records the *first matching role*; the clause text stays authoritative. This is
why the renderer must show clause text, not a paraphrase of the label.

### 1.3 Separators actually used

| Sequence | Occurrences (whole corpus) | Structural? |
|---|---|---|
| `;` | 73 | **yes** — clause boundary in thesis and lesson |
| `,` | 69 | **yes** — clause boundary in thesis/journal; *never* inside parentheses (see 1.3.1) |
| `. ` (sentence dot) | 21 | **yes** — journal summary and English lesson |
| `(` `)` | 120 | grouping; **never a boundary** |
| `/` | 132 | inside tokens (`H4/H1/M15`, `EMA20/50`, `107.35/107.43`, `4/4`) — never a boundary |
| `&` | 13 | conjunction **inside** a clause (`SL above H1 EMA20 & swing high 91.257`) — never a boundary |
| `->` | 5 | price path (`SL 0.67352 -> TP 0.67080`, `3866->3833`) — never a boundary |
| `:` | 26 | inside clock times (`09:30`, `16:00`) and lesson colons — never a boundary |
| `+` | 30 | `+1.00R`, `swing high + ~1.3x M15 ATR` — never a boundary |
| `~` | 4 | approximation (`~1.3x`, `~74 จุด`) |
| `·` (U+00B7) | 0 | not in use |
| `\|` | 0 | **not in use — reserved by this contract as illegal** |
| newline | 0 | **not present — reserved as illegal** |
| backtick | 0 | **not present — reserved as illegal** |
| markdown table / bullet | 0 | **not present — reserved as illegal** |

#### 1.3.1 The parenthesis case that breaks a naive parser

`TP 0.6708 (2.0R, within ADR)` and `SL 90.92 above M15 EMA50 (90.72) & today_high` both contain a comma or a
meaningful group **inside** parentheses. A `split(',')` loses `within ADR` (a semantics flag, not decoration)
and cuts a reference price in half. Therefore: **depth-aware splitting is mandatory**, and `within ADR` is
lifted into `facts.tp.withinAdr`, not discarded.

### 1.4 Numbers and units

| Unit in text | Examples | Note |
|---|---|---|
| `USC` | `+18.81 USC`, `-22.50 USC`, `risk 113.18/93.0 USC` | signed and unsigned both occur |
| `R` | `2.0R`, `+1.00R`, `2.21R`, `RR 1.58`, `1.58R` | **four spellings** of the same idea |
| `x … ATR` | `1.5x H1 ATR`, `2.7x M15 ATR`, `~1.3x M15 ATR`, `>2.5x M15 ATR` | multiple + timeframe |
| `pips` | `7.5 pips`, `15.8 pips` | lessons only |
| `จุด` (Thai "points") | `750 จุด`, `~74 จุด`, `39 จุด` | lessons only |
| `%` | `78.6%` (candle body), `+0.82 USC` | lessons |
| `lot` | `0.6 lot` | lessons |
| bare prices | `0.6708`, `107.62`, `65081.74`, `51130` | decimals vary 0–5 |
| ranges | `107.35-107.43`, `90.40-90.49`, `65081.74-65201.31` | hyphen, **not** a minus sign |
| ratios / pairs | `4/4 positions`, `113.18/93.0`, `64743/64803` | slash |
| arrows | `SL 0.67352 -> TP 0.67080`, `3866->3833` | path, not arithmetic |
| signs | `-22.50`, `+1.00R`, `(-28.0 USC)` | signed inside parentheses |

Nothing in the corpus uses a thousands separator, scientific notation, or Thai digits.

### 1.5 Language mixing

* Thesis values: **100 % English** (0 of 16 contain Thai characters) — enforce with ASCII punctuation only.
* Journal summaries: **100 % English** (ASCII), but riddled with abbreviations and parentheticals.
* Lessons: **21/22 Thai**, 1 fully English (`Entering AUDJPYc SELL on H4/H1/M15 BEAR alignment …`).
  Thai text embeds English technical tokens (`SL`, `TP`, `EMA20`, `SWEEP_HIGH_REJECT`, `mean-reversion`).
  Thai fragments are code-mixed without spaces: `โดนแรงรีบาวด์หลัง 21:00 UTC กวาดทะลุ M15 EMA20 และ H1 EMA20/50`.
  **Never split Thai on spaces**; it is not a word delimiter here.

### 1.6 What is *absent* today (negative evidence — do not build for it, do not fake it)

* **No explicit invalidation clause anywhere.** No `invalid if`, no `โครงสร้างเสียเมื่อ`. The SL rationale is the
  only falsification evidence. `facts.invalidation` is therefore **not** in `THESIS-1`; the addendum proposes an
  optional explicit field instead of guessing.
* No volume/size clause in theses (size lives in `volume`, `risk_usc`).
* No nested lists, no headings, no emoji inside these three fields.
* No guaranteed clause order *in principle*, although today alignment always comes first.

### 1.7 Legacy, missing and boilerplate

| Case | Count | Detail |
|---|---|---|
| `trades[].entry_reason === null` | 10 / 22 | the earliest trades predate reason capture; `index.html` already shows *"ไม่มีบันทึกเหตุผลสำหรับไม้นี้ (legacy trade)"* |
| `open_positions[].reason` missing | 0 | but the code path must tolerate it (`position.reason ? … : ''`) |
| `journal` rows with **neither** summary nor reason | 9 / 40 | all `action: "LEARN"` — the content lives in `lessons[]`, joined by `position_id` / `ts`, not in the journal row |
| `journal.reason` boilerplate | 3 | `AI adjust` (MODIFY), `AI cancel` ×2 (CANCEL) — these are CLI defaults from `mt5_bridge.py`, they carry no thesis |
| `journal.reason` system management | 2 | `Auto Partial TP 50% at +1.00R` and `Auto Partial TP 50% at +1.01R` — generated by the bridge's auto-partial logic, not by the AI |
| thesis without a SL clause | 3 / 16 | `SL` genuinely absent from the string (e.g. `… targeting H4 swing low 90.06`) |
| thesis without a TP clause | 2 / 16 | e.g. `M15 rejected EMA200 at 3889 … to 3858` |
| thesis without any RR token | 4 / 16 | RR is optional; the dashboard's computed R:R from prices is the fallback there |

Consequences already encoded below: `sl`, `tp`, `rr` are all **nullable for real data**, not defensive padding.

---

## 2. The canonical structured shape (normative)

Small on purpose: one object, one clause list, one facts bag, one parse report. No nested thesis trees.

### 2.1 `Thesis` object

| Field | Type | Null? | Meaning |
|---|---|---|---|
| `version` | `"THESIS-1"` | no | contract version; a renderer MUST ignore unknown versions gracefully |
| `kind` | `"thesis" \| "journal" \| "lesson"` | no | which grammar was applied (see 2.6) |
| `raw` | `string` | no | **verbatim** input, unmodified, always renderable |
| `ok` | `boolean` | no | `true` iff `parse.mode === "clauses"` |
| `lang` | `"en" \| "th" \| "mixed" \| "unknown"` | no | `mixed` when the string contains both Thai and Latin letters |
| `clauses` | `Clause[]` | no (may be `[]` only if `raw` is `""`) | ordered, lossless |
| `facts` | `Facts` | no | best-effort mirrors; every member nullable |
| `parse` | `ParseReport` | no | what the parser actually managed to do |

### 2.2 `Clause`

| Field | Type | Null? | Meaning |
|---|---|---|---|
| `label` | enum (2.5) | no | exactly one |
| `text` | `string` | no | verbatim slice; **untrimmed** (renderers `.trim()` for display) |
| `sep` | `string` | no | the verbatim separator that followed this clause in `raw`; `""` for the last |
| `nums` | `Num[]` | no (may be `[]`) | numeric tokens inside `text` |

Lossless invariant (MUST hold, assertable in a test):

```js
clauses.map(c => c.text + c.sep).join("") === raw
```

### 2.3 `Num`

| Field | Type | Null? | Meaning |
|---|---|---|---|
| `raw` | `string` | no | exact slice of `text`, sign included when it is a sign |
| `value` | `number` | no | numeric value, sign applied (so `raw: "-22.50"` → `value: -22.5`) |
| `unit` | enum (2.4) | no | `USC \| USD \| R \| PIPS \| POINTS \| PCT \| LOT \| ATR_MULT \| PRICE \| RATIO \| NONE` |
| `sign` | `-1 \| 0 \| 1` | no | `0` = unsigned. The sign is already inside `value` |
| `start` | `int` | no | UTF-16 offset of `raw` inside `text` (JS string index) |
| `end` | `int` | no | exclusive |
| `text.slice(start, end) === raw` | | | MUST hold |

`unit` is *suffix recognition*, not semantics: `NONE` means no recognised suffix. This deliberately happens to the
first member of a range or arrow (`65081.74` in `65081.74-65201.31`, `3866` in `3866->3833`) because a range member
is not a scalar price. Use `raw` and the clause text for those.

### 2.4 `Facts`

All members nullable / possibly empty. Absent means **"the text did not state it"**, never "not applicable".

| Field | Type | Meaning |
|---|---|---|
| `bias` | `"BULL" \| "BEAR" \| null` | first bias word anywhere in `raw`; `BULLISH→BULL`, `BEARISH→BEAR` |
| `timeframes` | `string[]` | from the leading alignment expression if present, else first-seen order; `["H4","H1","M15"]` |
| `alignment` | `{tf, bias}[]` | mirror for machine readers; `[]` when `bias` is null or no TFs found |
| `sl` | object \| null | see below |
| `tp` | object \| null | see below |
| `rr` | `number \| null` | RR **as written** (`(2.0R)`, `(RR 1.58)`, `2.21R`, global `+2.13R` fallback) |
| `levels` | `{name, kind, tf, price}[]` | every level phrase found, in order of appearance, duplicates allowed |
| `rsi` | `{tf, value, state} \| null` | `state` ∈ `"oversold" \| "overbought" \| null` |
| `session` | `string \| null` | first of `OffHours/Rollover, Rollover, London/NY overlap, London, Tokyo, Asia, NY` that appears |
| `risk` | object \| null | `{openUsc, maxUsc, slotsOpen, slotsMax, rMultiple}` — each nullable |
| `pnlUsc` | `number \| null` | first **signed** `±n USC` (so `risk 20.0 USC` never lands here) |
| `symbols` | `string[]` | e.g. `["AUDUSDc"]`, first-seen order, deduplicated |
| `sides` | `("BUY"\|"SELL")[]` | first-seen order |

`sl` object:

| Field | Type | Meaning |
|---|---|---|
| `price` | `number \| null` | only when a number **immediately** follows `SL` (allowing `at`/`is`/`=`) |
| `ref` | `string \| null` | the level phrase verbatim, e.g. `"today_high"`, `"H1 EMA20"`, `"sweep high"` |
| `refKind` | enum \| null | normalised: `PDH, PDL, today_high, today_low, today_open, session_low, session_high, swing_high, swing_low, sweep_high, sweep_low, EMA<n>, support, resistance, unknown` |
| `refPrice` | `number \| null` | only when a number immediately follows the ref phrase (`today_high 107.57`) |
| `atrMultiple` | `number \| null` | `1.5` from `(1.5x H1 ATR)` / `~1.3x M15 ATR` |
| `atrTf` | `string \| null` | `"H1"`, `"M15"` |
| `raw` | `string \| null` | the exact window the extractor used — provenance for tooltips/tests, **never displayed as the thesis** |

`tp` object: same shape plus `rr` (number\|null) and `withinAdr` (boolean). `withinAdr` is `true` when the TP clause
says `within ADR`; that is a **semantics flag, not decoration** and must not be dropped.

### 2.5 `label` enum

| Label | Valid for | Renderer chip idea |
|---|---|---|
| `ALIGNMENT` | thesis, journal | `BEAR · H4 H1 M15` |
| `TRIGGER` | thesis, journal | `SETUP` |
| `CONTEXT` | thesis, journal | `CTX` (RSI, session, time) |
| `STOP` | thesis, journal | `SL` |
| `TARGET` | thesis, journal | `TP` |
| `MANAGEMENT` | thesis, journal | `PARTIAL / FREE-ROLL / BE` |
| `RISK` | thesis, journal | `RISK` |
| `RATIONALE` | journal | `NO TRADE` |
| `OUTCOME` | lesson | `RESULT` |
| `CAUSE` | lesson | `WHY` |
| `RULE` | lesson | `RULE` |
| `BOILERPLATE` | thesis, journal | muted, or omitted with a one-line placeholder |
| `NOTE` | all | no chip — plain sentence |
| `UNPARSED` | all (only as the single clause of `mode: "raw"`) | no chip — plain paragraph |

### 2.6 `parse.mode` — the four states the renderer switches on

| `mode` | `ok` | Renderer MUST |
|---|---|---|
| `"clauses"` | `true` | render the clause list, in order, with chips |
| `"prose"` | `false` | render `raw` as one paragraph (chips from `facts` allowed) |
| `"raw"` | `false` | render `raw` escaped, preserving nothing but text; **no chips at all** |
| `"boilerplate"` | `false` | render a muted, de-emphasised line, or omit it if the surface has a better placeholder |

`parse` also carries `labels` (sorted array of distinct labels present) and `unparsed` (count of `NOTE` clauses).

### 2.7 Worked examples (real data, not invented)

**One open position** — `open_positions[0].reason`:

```json
{
  "version": "THESIS-1",
  "kind": "thesis",
  "raw": "H4/H1/M15 BEAR aligned; M15 swept H1 EMA20 (0.67413) & rejected bearish; SL at today_high (1.5x H1 ATR), TP 0.6708 (2.0R, within ADR)",
  "ok": true,
  "lang": "en",
  "clauses": [
    { "label": "ALIGNMENT", "text": "H4/H1/M15 BEAR aligned", "sep": "; ", "nums": [] },
    { "label": "TRIGGER", "text": "M15 swept H1 EMA20 (0.67413) & rejected bearish", "sep": "; ",
      "nums": [{ "raw": "0.67413", "value": 0.67413, "unit": "PRICE", "sign": 0, "start": 20, "end": 27 }] },
    { "label": "STOP", "text": "SL at today_high (1.5x H1 ATR)", "sep": ", ",
      "nums": [{ "raw": "1.5", "value": 1.5, "unit": "ATR_MULT", "sign": 0, "start": 18, "end": 21 }] },
    { "label": "TARGET", "text": "TP 0.6708 (2.0R, within ADR)", "sep": "",
      "nums": [
        { "raw": "0.6708", "value": 0.6708, "unit": "PRICE", "sign": 0, "start": 3, "end": 9 },
        { "raw": "2.0", "value": 2.0, "unit": "R", "sign": 0, "start": 11, "end": 14 }
      ] }
  ],
  "facts": {
    "bias": "BEAR",
    "timeframes": ["H4", "H1", "M15"],
    "alignment": [{ "tf": "H4", "bias": "BEAR" }, { "tf": "H1", "bias": "BEAR" }, { "tf": "M15", "bias": "BEAR" }],
    "sl": { "price": null, "ref": "today_high", "refKind": "today_high", "refPrice": null,
            "atrMultiple": 1.5, "atrTf": "H1", "raw": "at today_high (1.5x H1 ATR)" },
    "tp": { "price": 0.6708, "ref": null, "refKind": null, "refPrice": null,
            "rr": 2.0, "withinAdr": true, "raw": "0.6708 (2.0R, within ADR)" },
    "rr": 2.0,
    "levels": [
      { "name": "EMA20", "kind": "EMA20", "tf": "H1", "price": null },
      { "name": "today_high", "kind": "today_high", "tf": null, "price": null }
    ],
    "rsi": null, "session": null, "risk": null, "pnlUsc": null, "symbols": [], "sides": []
  },
  "parse": { "mode": "clauses", "labels": ["ALIGNMENT", "STOP", "TARGET", "TRIGGER"], "unparsed": 0 }
}
```

Note `facts.sl.price` is `null` while `ref` and `atrMultiple` are set: **the sentence never states a SL price** —
it states a level. A renderer that assumed a numeric SL would fail here (9 of 27 thesis parses are in this state).

**One lesson** — `lessons[]` for the UKOILc -35.86 USC loss:

```json
{
  "version": "THESIS-1",
  "kind": "lesson",
  "raw": "SELL UKOILc 90.994 SL 91.320 (-35.86 USC) โดนแรงดีดช่วงก่อนเปิด NY ทะลุ H1 EMA20 ขึ้นไป 92.321; แม้ M15 จะมี SWEEP_HIGH_REJECT แต่ SL 0.326 (ไม่ถึง 1x M15 ATR) เหนือไส้สั้นๆ แคบเกินต้านแรงดีด mean-reversion ของน้ำมัน",
  "ok": true,
  "lang": "mixed",
  "clauses": [
    { "label": "CAUSE", "sep": "; ",
      "text": "SELL UKOILc 90.994 SL 91.320 (-35.86 USC) โดนแรงดีดช่วงก่อนเปิด NY ทะลุ H1 EMA20 ขึ้นไป 92.321",
      "nums": [
        { "raw": "90.994", "value": 90.994, "unit": "PRICE", "sign": 0, "start": 12, "end": 18 },
        { "raw": "91.320", "value": 91.32, "unit": "PRICE", "sign": 0, "start": 22, "end": 28 },
        { "raw": "-35.86", "value": -35.86, "unit": "USC", "sign": -1, "start": 30, "end": 36 },
        { "raw": "92.321", "value": 92.321, "unit": "PRICE", "sign": 0, "start": 88, "end": 94 }
      ] },
    { "label": "CAUSE", "sep": "",
      "text": "แม้ M15 จะมี SWEEP_HIGH_REJECT แต่ SL 0.326 (ไม่ถึง 1x M15 ATR) เหนือไส้สั้นๆ แคบเกินต้านแรงดีด mean-reversion ของน้ำมัน",
      "nums": [
        { "raw": "0.326", "value": 0.326, "unit": "PRICE", "sign": 0, "start": 38, "end": 43 },
        { "raw": "1", "value": 1.0, "unit": "ATR_MULT", "sign": 0, "start": 52, "end": 53 }
      ] }
  ],
  "facts": {
    "bias": null, "timeframes": ["H1", "M15"], "alignment": [],
    "sl": { "price": 91.32, "ref": "EMA20", "refKind": "EMA20", "refPrice": null,
            "atrMultiple": null, "atrTf": null, "raw": "91.320 (-35.86 USC) โดนแรงดีดช่วงก่อนเปิด NY ทะลุ H1 EMA20 ขึ้นไป 92.321" },
    "tp": null, "rr": null,
    "levels": [{ "name": "EMA20", "kind": "EMA20", "tf": "H1", "price": null }],
    "rsi": null, "session": "NY", "risk": null,
    "pnlUsc": -35.86, "symbols": ["UKOILc"], "sides": ["SELL"]
  },
  "parse": { "mode": "clauses", "labels": ["CAUSE"], "unparsed": 0 }
}
```

For lessons, `facts.sl`/`tp` are **best-effort only** (here `ref` is an artifact of the cause text). The
authoritative lesson metadata is already structured on the row: `tag`, `scope`, `outcome`, `exit_type`,
`profit_usc`, `position_id`. The renderer MUST read those, not parsed guesses.

---

## 3. Parsing rules (normative, deterministic)

### 3.1 Order of operations

1. **Type guard.** If `raw` is not a string, or is `null`/`undefined`, or `trim()` is empty → the renderer's
   existing "no thesis" placeholder. No `Thesis` object is produced for `""`.
2. **Kind selection** (caller, not guessed):

   | Value | Kind |
   |---|---|
   | `open_positions[].reason`, `pending_orders[].reason`, `trades[].entry_reason` | `thesis` |
   | `journal.reason` with `action` starting `OPEN` | `thesis` |
   | `journal.reason` otherwise (HOLD/MODIFY/CANCEL/CLOSE/PARTIAL_CLOSE) | `journal` |
   | `journal.summary` (any action) | `journal` |
   | `lessons[].lesson` | `lesson` |

3. **Give-up check** (section 3.7) — may short-circuit to `mode: "raw"`.
4. **Segment** into clauses (3.2).
5. **Label** each clause (3.4).
6. **Extract facts** from `raw` as a whole (3.5). Facts do **not** depend on clause labels, so a wrong label can
   never destroy a fact and a missing fact can never be invented by a label.
7. **Assemble** `parse` and `ok`.

### 3.2 Segmentation

Scan `raw` left to right, tracking **depth** over `(` and `)` (`[`/`]` treated the same). Only at depth 0:

* `kind: "thesis"` → separators `;`, `,`
* `kind: "journal"` → separators `;`, `,`, `. ` (period followed by a space)
* `kind: "lesson"` → separators `;`, `. ` — **never** `,` (Thai sentences use commas differently and splitting
  them shreds the narrative)

Algorithm (reference implementation):

```js
function sections(raw, kind) {
  var seps = kind === 'lesson' ? [';', '. '] : [';', ',', '. '];
  var out = [], buf = '', i = 0, depth = 0;
  while (i < raw.length) {
    var ch = raw[i];
    if (ch === '(' || ch === '[') depth++;
    else if (ch === ')' || ch === ']') depth = Math.max(0, depth - 1);
    var hit = null;
    if (depth === 0) { for (var k = 0; k < seps.length; k++) if (raw.startsWith(seps[k], i)) { hit = seps[k]; break; } }
    if (hit) {
      out.push({ text: buf, sep: hit });
      buf = '';                                        // reset, or every clause inherits the previous text
      i += hit.length;
      var j = i;
      while (j < raw.length && raw[j] === ' ') j++;      // trailing spaces belong to sep
      if (j > i) out[out.length - 1].sep = raw.slice(i - hit.length, j);
      i = j;
      continue;
    }
    buf += ch; i++;
  }
  if (buf !== '' || out.length === 0) out.push({ text: buf, sep: '' });
  return out;
}
```

Rules:

* `text` is **not trimmed** (the renderer trims for display). This is what makes the lossless identity exact even
  when `raw` starts or ends with a space.
* A separator's surrounding spaces are part of `sep`, so the identity holds with no "lost whitespace" class of bug.
* Splitting **never** happens at depth > 0 (`within ADR`, `(90.72)`, `(64743/64803)`, `(107.35-107.43)` stay whole).
* Never split on `&`, `/`, `->`, `:`, `+`, `~`, or on spaces. `&` joins two references of one clause
  (`SL above H1 EMA20 & swing high 91.257`); splitting there would orphan `swing high 91.257` from its `SL` label.
* Empty `text` between two adjacent separators is legal and keeps `sep` values honest; it is labelled `NOTE` and
  the renderer skips rendering empty text.

### 3.3 Trimming and display

`text` is verbatim. Renderers `trim()` and, per clause, MAY collapse internal runs of spaces for display only.
No other change is permitted: no re-casing, no punctuation fixes, no number formatting (a price string must
render exactly as written — `0.67413` must not become `0.67`).

### 3.4 Label assignment — one ordered table, first match wins

Pre-pass: `t = clause.text.trim()`, `low = t.toLowerCase()`.

| # | Label | Test (case-insensitive unless noted) |
|---|---|---|
| 1 | `BOILERPLATE` | `low` ∈ {`ai setup`, `ai exit`, `ai adjust`, `ai cancel`} (exact, after trim) |
| 2 | `ALIGNMENT` | `^(aligned\s+)?(D1|H4|H1|M15|M5|M1)(\s*/\s*(D1|H4|H1|M15|M5|M1))*\s+(bull|bear|bullish|bearish)\b` **or** `\b(bull|bear)\s+aligned\b` |
| 3 | `MANAGEMENT` | `free[- ]roll`, `partial`, `\bBE\b`, `break-?even`, `locked profit` |
| 4 | `STOP` | contains `\bSL\b` **and** (no `\bTP\b`/`targeting`/`target`, **or** the `SL` index is before the first TP/target index) |
| 5 | `TARGET` | `\bTP\b`, `\btargeting\b`, `\btarget\b` |
| 6 | `RISK` | `\b(risk|budget|slots?)\b` |
| 7 | `RATIONALE` | `\b(no new|no clean|lack|avoid|due to|holding|hold\s|wide .*spread|chasing)\b` |
| 8 | `CONTEXT` | `\b(rsi|utc|rollover|offhours|tokyo|london|asia|session)\b`, `overbought`, `oversold` |
| 9 | `TRIGGER` | `\b(swept|sweep|pullback|retest|rejected|reject|printed|broke|break|reclaim|confluence|bounce|lower high|higher low|lower low|higher high)\b` **or** clause starts with a timeframe token `^(D1|H4|H1|M15|M5|M1)\b` |
| 10 | `NOTE` | otherwise |

Order rationale, from real data:

* `MANAGEMENT` **before** `STOP` — `Free-Roll EURNZDc BUY (SL->1.9997)` contains `SL` but is management, not a stop
  rationale.
* `STOP` **before** `TARGET` — in `SL 3892 above H1 swing high 3889.06, TP 3833 …` the split already separates them,
  but a clause with both must be read as the stop.
* `RISK` **before** `RATIONALE` — `risk_guard active.` is a risk statement, not a no-trade argument.
* `RATIONALE` **before** `CONTEXT` — `Tokyo/Asia session mid-day lacks clean A+ market entry` is a rationale that
  merely mentions a session.
* `TRIGGER` **after** `CONTEXT` — `H1 RSI 27.5 oversold bounce toward M15 EMA20/50` is setup context and must not be
  pulled into `CONTEXT` just for the `RSI` word; it matches `bounce` → `TRIGGER`. Where `CONTEXT` fires, no trigger
  verb was present.

Lesson kind uses its own ordered table (3.4.1).

#### 3.4.1 Lesson labels (`kind: "lesson"`)

Thai is code-mixed and `ทำให้` ("thus causing") contains the imperative-looking `ให้`. **Strip `ทำให้` before
matching**, or the causal sentence is misread as an instruction.

| # | Label | Test |
|---|---|---|
| 1 | `RULE` | after removing `ทำให้`: `ห้าม`, `ต้อง`, `ควร`, `อย่า`, `ไม่ควร`, `ให้`, `\bmust\b`, `\bshould\b`, `\bnever\b`, `\bavoid\b` |
| 2 | `CAUSE` | `โดน`, `กวาด`, `รีบาวด์`, `สวิง`, `ไส้`, `แพ้`, `\bswept\b`, `\brejected\b`, `\bsurvived\b`, `\brebound`, `\bhit\b` |
| 3 | `OUTCOME` | `\bSL\b` or `\bTP\b` followed **within 40 characters by a number of ≥2 digits** |
| 4 | `NOTE` | otherwise |

Result on the live 22 lessons / 40 clauses: `CAUSE` 18, `RULE` 17, `OUTCOME` 4, `NOTE` 1. Read in order, a lesson
becomes *what happened* → *the rule* — exactly the pairing a human needs, with zero Thai rewriting.

`NOTE` **is legal in lesson kind** and must not be treated as a parse failure: one real clause
(`หากโครงสร้าง H1/M15 ยังเป็นขาลงชัดสามารถวาง TP ตามแนวรับถัดไปได้`) is a conditional remark with no number, no
prescription keyword and no market-action verb, so it stays `NOTE` and renders as plain prose. The 22 first clauses
are always `OUTCOME` or `CAUSE`; only second clauses can fall through to `NOTE`. (An earlier draft of this rule said
"any ≥2-digit number in the clause", which wrongly matched the `15` inside `M15` and would have labelled that clause
`OUTCOME`. The number must follow the `SL`/`TP` token.)

### 3.5 Facts extraction

Extraction runs over **`raw`**, not over labels. Every regex below is applied to the whole string; the `SL`/`TP`
windows are bounded by the next top-level separator (3.2) and capped at 120 characters.

**`bias`** — first `(BULLISH|BEARISH|BULL|BEAR)`; normalise `BULLISH→BULL`, `BEARISH→BEAR`.

**`timeframes` / `alignment`** — if the string starts with an alignment expression, take the TFs from *that
expression only* (so `1.5x H1 ATR` cannot contribute `H1`); otherwise first-seen TFs in the string. `alignment` is
`timeframes.map(tf => ({tf, bias}))`, only when `bias !== null`.

**`sl`** — find the first `\bSL\b`; window = from there to the next top-level separator, max 120 chars.

1. `price`: `^\s*(?:at|is|=)?\s*([0-9]+(?:\.[0-9]+)?)\b` **only** — i.e. an immediately-adjacent number. `SL at
   today_high`, `SL above H1 EMA20` and `SL below today_low/H1 EMA50` correctly yield `null`.
2. `ref`/`refKind`/`refPrice`: **first-mentioned** level phrase in the window (position ordered, not vocabulary
   ordered), matched against the level vocabulary in 3.5.1. `refPrice` only from immediate adjacency
   (`today_high 107.57` → `107.57`); numbers inside parentheses are **not** used (`EMA20 (0.67413)` → `refPrice:
   null`), because `(1.5x H1 ATR)` would otherwise be read as a price.
3. `atrMultiple`/`atrTf`: `([0-9]+(?:\.[0-9]+)?)\s*x\s*(D1|H4|H1|M15|M5|M1)\s+ATR` (a leading `~` or `>` is ignored but
   must remain in the text).

**`tp`** — first `\bTP\b` / `\btargeting\b` / `\btarget\b`; same window and steps, plus:

* `rr`: `RR\s*([0-9]+(?:\.[0-9]+)?)` **or** `([0-9]+(?:\.[0-9]+)?)\s*R\b`. Both spellings are live:
  `TP 107.00 (RR 1.58)` and `TP 89.58 … (RR 1.58)` use the first, `(2.0R)`, `(2.21R)`, `(2.63R)` the second.
* `withinAdr`: `/within\s+ADR/i` anywhere in the TP window.

**`rr` (top level)** — `tp.rr`; else first `RR n.nn` anywhere; else the **last** `n.nnR` in the string
(`+2.13R` in a lesson). A `2.1x` ATR multiple is never an RR.

**`levels[]`** — every match of the 3.5.1 vocabulary, position-ordered, `{name, kind, tf, price}`:

* `name` = verbatim matched phrase (`sl20`, `EMA20`, `today_high`, `sweep high`).
* `kind` = normalised: `sl20`/`swing low` → `swing_low`; `EMA<n>` keeps its number.
* `tf` = a timeframe token in the 7 characters before the phrase, else `null`.
* `price` = immediate adjacency only, else `null` (ranges and parentheticals stay in `nums`/text).

**`rsi`** — `\b(D1|H4|H1|M15|M5|M1)\s+RSI\s+([0-9]+(?:\.[0-9]+)?)`; `state` = `oversold`/`overbought` if that word
appears anywhere in the string.

**`session`** — first match of `OffHours/Rollover`, `Rollover`, `London/NY overlap`, `London`, `Tokyo`, `Asia`, `NY`.

**`risk`** — `risk\s*(\d+\.?\d*)\s*/\s*(\d+\.?\d*)\s*USC` (or the same without the `risk` word) → `openUsc,maxUsc`;
`(\d+)\s*/\s*(\d+)\s*(?:open\s+)?positions` → `slotsOpen,slotsMax`; for `kind: "journal"` a standalone `±nR` → `rMultiple`.

**`pnlUsc`** — first `[(\s]([+-]\d+(?:\.\d+)?)\s*USC`: **signed** only, so `risk 20.0 USC` is not a P&L.

**`symbols`** — `\b[A-Z]{2,6}\d{0,2}c\b` (the broker's `c` suffix: `AUDUSDc`, `US30c`, `UKOILc`, `BTCUSDc`),
first-seen, deduplicated. **`sides`** — `\b(BUY|SELL)\b`, first-seen.

#### 3.5.1 Level vocabulary

| Pattern | `kind` |
|---|---|
| `today_high`, `today_low`, `today_open` | same name |
| `PDH`, `PDL` | same name |
| `session low`, `session high` | `session_low`, `session_high` |
| `sl20`, `swing low` | `swing_low` |
| `swing high` | `swing_high` |
| `sweep high`, `sweep low` | `sweep_high`, `sweep_low` |
| `EMA20`, `EMA50`, `EMA200`, `EMA<n>` | `EMA<n>` |
| `support`, `resistance` | same name |
| anything else in a stop/target clause | `unknown` (with `ref` verbatim) |

`sl20` is the writer's abbreviation for the 20-bar swing low — normalise it, keep the text.

### 3.6 Numeric tokenisation (`nums`)

A `Num` is **one unsigned decimal magnitude with an optional sign**; separators are never part of a token.

* Sign: `-` is a sign only when it is at the start of `text` or preceded by a space, `(`, `,` or `;`. So
  `(-22.50 USC)` → `-22.5`, while `107.35-107.43` and `65081.74-65201.31` are two positive tokens. `+` is a sign
  when preceded by the same set (`+1.00R`).
* **Skip** a number when the preceding character is a letter or `:` (`H4`, `M15`, `EMA20`, `D1`, `09:30`, `16:00`),
  or when the following character is `:` (`09:30`). This is what keeps `M15` from producing a `15` token.
* **Skip** a number preceded by `/` when it is an EMA period compound (`EMA20/50` → no `50` token) — the compound
  is a name, not a number.
* `unit` from the suffix within ~14 characters: `USC`, `USD`, `R`, `pips`, `จุด` (→ `POINTS`), `%` (→ `PCT`),
  `lot` (→ `LOT`), `x <TF> ATR` (→ `ATR_MULT`), a following `/` (→ `RATIO`), whitespace/`)`/end (→ `PRICE`),
  otherwise `NONE`.
* `start`/`end` are UTF-16 offsets (JS string indices) into `clause.text`, and `text.slice(start,end) === raw` MUST
  hold. No look-behind (`(?<!…)`) is required anywhere: check the preceding character explicitly, so the parser
  runs on any browser the dashboard supports.

### 3.7 Where parsing MUST give up

| Condition | Result |
|---|---|
| `raw` is not a string, `null`, `undefined`, or `trim() === ""` | *no* `Thesis`; the caller renders its own placeholder |
| `raw` contains `\n`, `\r` | `mode: "raw"`, one clause `{label: "UNPARSED", text: raw, sep: "", nums: []}` |
| `raw` contains `\|` or a backtick | `mode: "raw"` (the writer is forbidden these; treat their presence as free-form text) |
| `raw.length > 1200` | `mode: "raw"` (no live value exceeds 316) |
| segmentation yields 1 clause **and** it is `NOTE` | `mode: "prose"` |
| segmentation yields ≥ 2 clauses, or 1 clause with any structural label | `mode: "clauses"` |
| the single clause is `BOILERPLATE` | `mode: "boilerplate"` |
| an unrecognised `kind` | treat as `thesis`; never throw |

Whatever the branch, `raw` and the lossless identity survive, and `mode: "raw"` still renders the original text.

### 3.8 Invariants (must hold for every input, fuzz included)

1. **Lossless:** `clauses.map(c => c.text + c.sep).join("") === raw`.
2. **Total:** the function returns a `Thesis` for every non-empty string; it never throws, never returns `null`,
   never leaves `undefined` in a documented field.
3. **No invention:** every number in `facts` appears verbatim in `raw`; every `levels[]` entry appears verbatim in
   `raw`. If a pattern does not match, the field is `null`, not a guess.
4. **No mutation:** `raw` is byte-identical to the input.
5. **Idempotent:** parsing the same string twice yields deeply-equal results.

Reference implementation check on the live snapshot: **69/69 text values parse losslessly**, `mode` distribution
`clauses: 66, boilerplate: 3`, and **0 `NOTE` clauses across all 16 thesis values** — every published thesis gets
a structural label today. Residual `NOTE` clauses exist only in journal prose (7) and are displayed as plain text.

### 3.9 Ambiguity register (each real, each resolved)

| Ambiguous input | Risk | Rule |
|---|---|---|
| `H4/H1/M15 BEAR aligned; M15 EMA20 pullback zone 27040 with SL 27240 above H1 EMA20 (2.1R)` | `(2.1R)` sits in a **STOP** clause but is the trade's RR; there is no TP clause at all | `rr` is extracted from the whole string, not from the TP clause only → `rr = 2.1`, `tp = null`. Never assign an `R` token to `sl`. |
| `TP 107.00 (RR 1.58)` vs `TP 89.65 … (2.63R)` | two RR spellings | both patterns are mandatory (3.5) |
| `SL at today_high (1.5x H1 ATR)` | no numeric SL | `sl.price = null`, `ref = today_high`, `atrMultiple = 1.5` |
| `SL above H1 EMA20 & swing high 91.257` | two refs in one clause; `&` is not a separator | `ref` = first mentioned (`EMA20`), both appear in `levels[]`, text intact |
| `107.35-107.43`, `90.40-90.49`, `65081.74-65201.31` | hyphen looks like minus; a range is not a scalar | two positive `Num`s; no scalar price in `facts` from a range |
| `3866->3833` (lesson) | arrow | two `Num`s; `->` never a separator |
| `M15 EMA20 / 16:00 resistance (64250)` | `/` and `:` inside a clause; `16:00` is a clock, not a price | `/` and `:` are never separators; `16` and `00` produce no tokens (colon guard) |
| `risk 113.18/93.0 USC (4/4 positions)` | slash ratios | `risk.openUsc/maxUsc` and `slotsOpen/slotsMax`; no `rr` from `4/4` |
| `ALIGNMENT … (H4 RSI 41.8)` | RSI inside the alignment clause | `bias`/`timeframes` still come from the alignment expression; `rsi` from the whole string |
| `1.5x H1 ATR`, `~1.3x M15 ATR`, `>2.5x M15 ATR` | `>`/`~` prefixes; `x` suffix | `atrMultiple` = the number; prefixes stay in the text; `x` never becomes a token |
| Thai `ทำให้ถือผ่าน…` | contains `ให้` (imperative) inside a causal verb | strip `ทำให้` before lesson keyword matching |
| `Auto Partial TP 50% at +1.00R` | contains `TP` but is auto-management | `MANAGEMENT` is checked before `STOP`/`TARGET` |
| `AI cancel` | no content at all | `BOILERPLATE` → `mode: "boilerplate"`, muted or omitted |
| `65081.74` in a range | first member has no suffix → `unit: "NONE"` | legal by design; use `raw`, do not infer a price |

---

## 4. Backward compatibility (the corpus already published)

These rules are the reason nothing on the dashboard may look broken after the change.

1. **Nothing is rewritten.** All 69 existing strings render exactly as today when `parse.mode !== "clauses"`
   (`prose`, `raw`) — and even in `clauses` mode the concatenation of clause texts is the original sentence.
2. **10 trades with `entry_reason === null`** keep the existing legacy message
   *"ไม่มีบันทึกเหตุผลสำหรับไม้นี้ (legacy trade)"*. They MUST NOT show an empty thesis card, a fake parse, or a
   "parsing failed" warning — absence is not failure.
3. **9 `journal` rows (all `action: "LEARN"`) have neither `summary` nor `reason`.** Today `journalRow` prints `—`.
   The renderer MUST keep a neutral placeholder; it MAY additionally link to the lesson via `position_id`/`ts`, but
   MUST NOT invent a reason.
4. **5 `journal.reason` ops strings** (`AI adjust`, `AI cancel` ×2, `Auto Partial TP 50% at +1.00R` / `+1.01R`) parse to
   `boilerplate`/`MANAGEMENT`. They are not theses; show them muted or replace them with a human label
   (`Auto partial TP at +1.0R`) that is **clearly derived from**, not substituted for, the stored string.
5. **21 Thai lessons** carry `lang: "mixed"`. Thai never gets word-split; only `;` and `. ` are boundaries.
   The row's `tag`/`scope`/`outcome` remain the authoritative metadata (they are already in `data.json`).
3 of 22 lessons stay a single clause; they still get one `CAUSE`/`RULE` label and render as one paragraph.
6. **`open_positions[].reason` / `pending_orders[].reason` may be absent.** The current guard
   (`position.reason ? … : ''`) stays.
7. **Unknown future text** (a writer change, a new action, a hand-edited row): the parser degrades to `NOTE` /
   `prose` / `raw`. The dashboard MUST never show a parse error to the user; at worst it shows the raw sentence,
   which is what it shows today.
8. **Extra or renamed fields** in `data.json` are ignored. The parser reads only the documented field names.

---

## 5. Agreement — the contract both sides sign

**This section is the agreed contract. If a future change contradicts it, this document is amended first and both
sides re-read it; there is exactly one contract, not a menu of options.**

### 5.1 What the WRITER guarantees (`thesis-author` side)

The live prompt is **not** modified in this task (see 7). Within the current prompt, and for every entry produced
until THESIS-2:

1. Thesis fields continue to be **single-line English** text with ASCII punctuation; `;` and `,` remain the clause
   separators; `&`, `/`, `->`, `:`, `+`, `~` stay *inside* clauses.
2. The recognised vocabulary keeps its meaning: `SL`, `TP`, `targeting`, `RR n.nn`, `n.nnR`, `x <TF> ATR`,
   `today_high/low/open`, `PDH`, `PDL`, `swing high/low`, `sweep high/low`, `EMA<n>`, `sl20`, `long`/`short` sides as
   `BUY`/`SELL`, USC / R / pips / จุด / % units.
3. The leading multi-timeframe expression (`H4/H1/M15 BEAR aligned` or `Aligned …`) keeps appearing first when a
   bias exists.
4. No `\n`, no `|`, no backticks, no markdown tables, no bullet characters, no emoji inside these fields.
5. Thai stays in `lessons[].lesson`; theses stay English.
6. The writer does not promise a numeric SL price or an RR token — those are optional, and the contract treats them
   as nullable (proven above: 9/27 stop clauses are reference-only, 4/16 theses state no RR).
7. If the owner later approves the addendum, explicit fields **win** over parsing, and this document is bumped to
   `THESIS-2` in the same change. Until then the writer emits nothing new.

### 5.2 What the RENDERER guarantees (`thesis-ui` side)

1. Implement exactly the field names, label enum and precedence in sections 2–3 — no local embellishments, no
   extra labels, no renaming.
2. Always keep the raw string reachable (e.g. a `<details>` body, a title attribute, or a copy affordance). A user
   must be able to see exactly what the bot wrote.
3. Render **every** clause in order; `NOTE`/`UNPARSED` text renders as plain prose, never dropped and never
   reordered.
4. `mode: "prose"`/`"raw"`/`"boilerplate"` render as text (no chips, no fabricated structure).
5. Never print `undefined`/`null`/`NaN`; a null fact is simply absent. Never print `facts.*.raw`.
6. Escape all text (existing `esc()`); build no HTML from parsed text except through escaping. No `innerHTML` of raw
   thesis text.
7. Do not reformat numbers found in clause text. `0.67413` stays `0.67413`; the formatted/chip values come from
   `facts`/`nums` in their own elements.
8. Thai text is rendered with normal word-breaking (`overflow-wrap: anywhere` as today); never inserted into
   `white-space: nowrap` blocks that could cut it.
9. For pending orders, keep the **computed** R:R from `trigger/SL/TP` as the authoritative number; `facts.rr` is a
   secondary "as written" value and must be labelled as such if both are shown.
10. Chips carry text labels, not colour alone (existing tone system plus a word); no icon-only semantics.
11. Cap the visual load: at most 5 chips per thesis (exactly the 2–5 clauses of today), `NOTE` clauses unbounded
    because they are just sentences.
12. Cost: parsing 69 strings happens inline at render, no new requests, no new dependencies, no build step.
13. Degrade gracefully: unknown `version`, unknown `kind`, unknown `mode`, extra keys → the raw text is still shown.

### 5.3 Out of scope / must not change here

* The `mt5-ai-trader` prompt, `mt5_bridge.py`, the Hermes state — untouched.
* `data.json` and `index.html` are owned elsewhere; this document only describes the contract.
* No new database column is required for THESIS-1; the shape is derived at render time. Persisting it is a possible
  THESIS-2 follow-up.

### 5.4 Change process

Any change to labels, field names or precedence requires: (a) a new section in this file, (b) a `version` bump,
(c) both sides re-running the fixture table in Appendix B. Purely visual changes (chips, colours, layout) need no
contract change.

---

## 6. Budget limits the writer can rely on

| Item | Budget | Evidence |
|---|---|---|
| `thesis` total | **80–220 chars** (hard 260) | live 89–212, mean 145 |
| one thesis clause | **≤ 70 chars** preferred, hard 110 | live clause median 47, max 188 (the long UKOILc sweep clause) |
| clauses per thesis | **2–5** | live: 7×4, 4×3, 3×2, 2×5 |
| `journal.summary` | ≤ 300 chars, ≤ 5 sentences | live 119–282 |
| `journal.reason` (ops) | ≤ 60 chars | live 9–212 |
| `lesson` | 120–400 chars, 1–3 sense groups | live 145–316 |
| parentheses | balanced, ≤ 2 nested levels, never contain `;` | live: always balanced, depth ≤ 1 |
| characters | printable ASCII for `thesis`; Thai + ASCII for `lesson`; **no** `\n`, `\r`, `\|`, `` ` ``, tab, emoji, markdown, tables, bullets | 0 occurrences of any forbidden form in the corpus |
| numbers | plain decimal only (no thousands separator, no exponent, no Thai digits) | 0 occurrences |

If the writer ever exceeds these, the renderer still works: oversize → `mode: "raw"`, no data lost.

---

## Appendix A — verbatim samples that shaped the rules

```
H4/H1/M15 BEAR aligned; M15 swept H1 EMA20 (0.67413) & rejected bearish; SL at today_high (1.5x H1 ATR), TP 0.6708 (2.0R, within ADR)
H4/H1/M15 BEAR aligned pullback to M15 EMA20/50 below H1 EMA20, SL above H1 EMA20 & swing high 91.257, targeting PDL 89.70 (2.5R)
H4/H1/M15 BEAR pullback SELL LIMIT into M15 swing high/EMA50 (50960); SL 51130 above H1 EMA20 (2.1x M15 ATR); TP 50580 above PDL
H4/H1/M15 BEAR aligned; M15 09:30 swept H1 EMA20 (91.03) up to 91.219 and printed SWEEP_HIGH_REJECT, M15 09:45 lower high 90.99; SL 91.32 above sweep high 91.219 (1.55x M15 ATR), TP 89.65 above H4 sl20 89.564 (2.63R)
H4/H1/M15 BEAR aligned, M15 pullback rejected off EMA50 (27385.88) with bearish candle 01:45, SL 27425 above swing high + ~1.3x M15 ATR, TP 27135 front-running H4 swing low 27127.9 (1.80R)
H4/H1/M15 BEAR aligned; M15 EMA20 pullback zone 27040 with SL 27240 above H1 EMA20 (2.1R)
H4/H1/M15 BEAR aligned; H1 RSI 27.5 oversold bounce toward M15 EMA20/50 (107.35-107.43); SL 107.62 above today_high 107.57 (2.7x M15 ATR); TP 107.00 (RR 1.58)
Aligned H4/H1/M15 BEAR pullback SELL LIMIT into H1 EMA20/M15 EMA50 (3866); SL 3892 above H1 swing high 3889.06; TP 3833 above H4 support 3832.19
```

Journal prose (no clause grammar — `mode: "prose"`, facts still extracted):

```
Hold AUDUSDc SELL 0.11 free-roll (+18.81 USC, SL 0.67352 -> TP 0.67080) and keep 3 pending limit orders (US30c 50960, GBPNZDc 2.4000, UKOILc 90.95). Tokyo/Asia session mid-day lacks clean A+ market entry.
OffHours/Rollover (22:00 UTC): 5/4 open positions (open risk 113.19/92.96 USC, 1 free-roll EURNZDc). Reviewed USTECc SL (-28.0 USC) and recorded lesson. All 5 open positions remain structurally aligned; holding without new entries due to risk/position cap and wide rollover spreads.
```

Residual `NOTE` text (must still render, no chip): `All 7 positions in profit (+46.96 USC total)`,
`logged 2 lessons (BTCUSDc/UKOILc)`, `risk_guard active.`, `keep US30c SELL LIMIT @ 50960`,
`Place XAUUSDc SELL LIMIT 0.01 @ 3879.0 (HTF BEAR H1 EMA50)`, `All 5 open positions remain structurally aligned`.

---

## Appendix B — fixture table (use these as renderer unit tests)

All 16 thesis values (15 distinct strings), parsed by the reference implementation. `sl`/`tp` show `price|refKind|refPrice|atr`.

| # | Source | Sym | Labels in order | bias | tf | rr | ADR | sl | tp |
|---|---|---|---|---|---|---|---|---|---|
| 1 | open | AUDUSDc | ALIGNMENT > TRIGGER > STOP > TARGET | BEAR | H4 H1 M15 | 2.0 | yes | `null\|today_high\|null\|1.5xH1` | `0.6708\|—\|null\|2.0R` |
| 2 | pending | UKOILc | ALIGNMENT > STOP > TARGET | BEAR | H4 H1 M15 | 2.5 | no | `null\|EMA20\|null\|—` | `null\|PDL\|89.70\|2.5R` |
| 3 | pending | GBPNZDc | ALIGNMENT > TARGET | BULL | H4 H1 M15 | 2.0 | no | `null` (no SL stated) | `null\|PDH\|null\|2.0R` |
| 4 | pending | US30c | ALIGNMENT > STOP > TARGET | BEAR | H4 H1 M15 | — | no | `51130\|EMA20\|null\|2.1xM15` | `50580\|PDL\|null\|—` |
| 5 | trade | AUDJPYc | ALIGNMENT > CONTEXT > STOP > TARGET | BEAR | H4 H1 M15 | 1.58 | no | `107.62\|today_high\|107.57\|2.7xM15` | `107.00\|—\|null\|1.58R` |
| 6 | trade | AUDUSDc | ALIGNMENT > TRIGGER > STOP > TARGET | BEAR | H4 H1 M15 | 2.0 | yes | `null\|today_high\|null\|1.5xH1` | `0.6708\|—\|null\|2.0R` |
| 7 | trade | XAUUSDc | ALIGNMENT > STOP > TARGET | BEAR | H4 H1 M15 | — | no | `3892\|swing_high\|3889.06\|—` | `3833\|support\|3832.19\|—` |
| 8 | trade | BTCUSDc | ALIGNMENT > TRIGGER > STOP > TARGET | BEAR | H4 H1 M15 M5 | 2.0 | no | `65000\|EMA20\|null\|1.2xH1` | `62750\|—\|null\|2.0R` |
| 9 | trade | EURNZDc | ALIGNMENT > TRIGGER > TRIGGER > STOP > TARGET | BULL | H4 H1 | 2.21 | no | `null\|today_low\|null\|—` | `2.0058\|—\|null\|2.21R` |
| 10 | trade | USTECc | ALIGNMENT > STOP | BEAR | H4 H1 M15 | **2.1** (from `(2.1R)` in the SL clause) | — | `27240\|EMA20\|null\|—` | `null` (no TP clause) |
| 11 | trade | BTCUSDc | ALIGNMENT > TRIGGER > STOP > TARGET | BEAR | H4 H1 M15 | 1.74 | no | `null\|today_high\|65146\|—` | `null\|PDL\|63826\|1.74R` |
| 12 | trade | UKOILc | ALIGNMENT > TRIGGER > TRIGGER > STOP > TARGET | BEAR | H4 H1 | 2.63 | no | `91.32\|sweep_high\|91.219\|1.55xM15` | `89.65\|swing_low\|89.564\|2.63R` |
| 13 | trade | UKOILc | ALIGNMENT > CONTEXT > STOP > TARGET | BEAR | H4 H1 M15 | 1.58 | no | `90.92\|EMA50\|null\|—` | `89.58\|swing_low\|89.564\|1.58R` |
| 14 | trade | USTECc | ALIGNMENT > TRIGGER > STOP > TARGET | BEAR | H4 H1 M15 | 1.80 | no | `27425\|swing_high\|null\|1.3xM15` | `27135\|swing_low\|27127.9\|1.80R` |
| 15 | trade | UKOILc | ALIGNMENT > TRIGGER > TARGET | BEAR | H4 H1 M15 | — | no | `null` (no SL stated) | `null\|swing_low\|90.06\|—` |
| 16 | trade | XAUUSDc | ALIGNMENT > TRIGGER | BEAR | H4 H1 M15 | — | — | `null` (no SL stated) | `null` (no TP clause) |

Journal summary label sequences (15 rows) — useful as a "prose tolerance" test:
`MANAGEMENT > CONTEXT`, `NOTE > MANAGEMENT > RISK > CONTEXT > RATIONALE`, `RATIONALE > NOTE > RISK`,
`CONTEXT > RATIONALE > RATIONALE`, `RISK > RATIONALE > RATIONALE`, `MANAGEMENT > STOP > NOTE > RISK`,
`MANAGEMENT > NOTE > RATIONALE`, `RISK > MANAGEMENT > RATIONALE`, `MANAGEMENT > RISK`,
`MANAGEMENT > NOTE > STOP`, `RATIONALE > RISK > RATIONALE`, `CONTEXT > STOP`, `RATIONALE > NOTE`, `STOP`,
`RATIONALE > TRIGGER > NOTE`.

Lesson label sequence — the first clause of a lesson is always `OUTCOME` or `CAUSE` (22/22); a second clause is
`RULE` (17) or, once in the corpus, `NOTE` (1). 18 of 22 lessons have two clauses, 4 have one.
