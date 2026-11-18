# Thesis prompt addendum — optional explicit fields (` [STRUCT] ` trailer)

> ## ⚠️ PROPOSAL ONLY — NOT APPLIED
>
> **This file is not part of the running bot.** The live `mt5-ai-trader` prompt has **not** been modified and
> must **not** be modified without the owner's explicit approval. Nothing described here is in effect today;
> the dashboard must keep working against the current free-text writer exactly as documented in
> [`thesis-contract.md`](./thesis-contract.md).
>
> **ข้อความนี้เป็นข้อเสนอเท่านั้น ยังไม่ถูกนำไปใช้** — ห้ามแก้พรอมป์ของบอทจริง (`mt5-ai-trader`) หรือ
> `mt5_bridge.py` ก่อนได้รับอนุมัติจากเจ้าของพอร์ต

**Companion to:** [`thesis-contract.md`](./thesis-contract.md) (`THESIS-1`).
**Effect if approved:** a new contract version `THESIS-2`, additive only.

---

## 1. Why this exists

`THESIS-1` proves the existing free text can be parsed losslessly — 16 unique theses, 69/69 text values, every
thesis clause labelled. But parsing has hard ceilings that no regex can lift, and they are all visible in today's
corpus:

| What the writer knows exactly | What parsing can only guess |
|---|---|
| Which clause is the invalidation condition | *No invalidation clause exists in the corpus at all* — the field would have to be invented |
| The intended RR when the sentence states none | 4 of 16 theses state no RR; a parser that computes one is inventing it |
| Whether `(2.1R)` in `… with SL 27240 above H1 EMA20 (2.1R)` is the RR | Guessable from position, but fragile: it sits in a STOP clause with no TP clause in the sentence |
| That `M15 09:30 … , M15 09:45 lower high 90.99` is one sweep story | Two clauses, split by the comma |
| The confidence/conviction that chose the risk size | Not in any thesis string |

The trailer adds those fields **without changing the human sentence**, so old readers, old dashboards and
old parsers keep working unchanged.

---

## 2. The encoding — one option, decided

The explicit fields are appended to the existing `--reason` value, after a reserved marker:

```
<unchanged human thesis, same grammar as today> [STRUCT] key=value; key=value; …
```

* Marker: the literal string ` [STRUCT] ` — one leading space, one trailing space. It contains **0 occurrences**
  in the current corpus (`#`, `[`, `]` are all unused today), so it cannot collide.
* The trailer is **optional and always last**. A reason without it is 100 % valid and parses exactly as `THESIS-1`
  does today.
* Pairs are separated by `; `. A value never contains `;` or `]`.
* Keys are lowercase and fixed; unknown keys are ignored by `THESIS-2`, which is what makes future additions safe.
* The human part before the marker keeps **every** rule of `THESIS-1` (English, ASCII punctuation, `;`/`,` clause
  separators, 80–220 chars).

### 2.1 Allowed keys

| Key | Type | Grammar | Required? | Example |
|---|---|---|---|---|
| `bias` | enum | `BULL` \| `BEAR` | optional | `bias=BEAR` |
| `tf` | list | 1–4 of `D1,H4,H1,M15,M5,M1`, comma-separated, no spaces, highest first | optional | `tf=H4,H1,M15` |
| `trigger` | text | ≤ 48 chars, no `;` and no `]` | optional | `trigger=M15 sweep+reject of H1 EMA20` |
| `inv` | text | ≤ 48 chars, the condition that proves the idea wrong (a level or a behaviour) | optional | `inv=M15 close above 0.6760` |
| `rr` | number | `0.1`–`99.9`, at most 2 decimals | optional | `rr=2.0` |
| `sl` | number | plain decimal price | optional | `sl=0.67490` |
| `tp` | number | plain decimal price | optional | `tp=0.67080` |
| `adr` | enum | `IN` \| `OUT` — target inside / outside the daily range envelope | optional | `adr=IN` |

Rules that make the change safe:

1. **Omit, never guess.** If a value is not truly known, leave the key out. A wrong `inv` is worse than none.
2. `rr` describes the trade as planned; `sl`/`tp` repeat the prices already in the sentence (they let the reader
   skip number extraction, they do not replace the sentence).
3. The marker appears at most once, at the end. Never in `--lesson`, never in a `HOLD` journal summary, never in a
   Telegram-only report.
4. The human sentence must still make sense if the trailer is deleted with a text editor.

---

## 3. Paste-ready prompt section (Thai — the bot's prompt language)

Append this block to the `mt5-ai-trader` prompt, **only after owner approval**. It is written to match the
existing Thai prompt's tone and its "ห้าม" style guardrails.

```text
## รูปแบบ Thesis สำหรับแดชบอร์ด (Structured Trailer — ถ้าไม่มั่นใจให้ละเว้น)

ทุกครั้งที่สั่ง `open` / `limit` / `stop` และใส่ `--reason` ให้คงประโยคภาษาอังกฤษแบบเดิมทุกอย่าง
(เรียง ALIGNMENT -> TRIGGER -> SL -> TP คั่นด้วย `;` หรือ `,` ยาวไม่เกิน 220 ตัวอักษร ไม่มีขึ้นบรรทัดใหม่)
แล้วต่อท้ายด้วยก้อนข้อมูลเครื่องอ่านได้ **ถ้าคุณรู้ค่าจริง** ตามรูปแบบนี้:

    <ประโยคเดิม> [STRUCT] key=value; key=value; ...

คีย์ที่อนุญาต (มีหรือไม่มีก็ได้ ใส่เฉพาะที่รู้จริง):

- bias=BULL หรือ bias=BEAR           (ทิศทางตามโครงสร้าง HTF)
- tf=H4,H1,M15                        (1-4 ไทม์เฟรม เรียงสูงไปต่ำ คั่นด้วย comma ไม่มีช่องว่าง)
- trigger=<ข้อความ <=48 ตัวอักษร>     (ทริกเกอร์ที่ทำให้เข้า เช่น M15 sweep+reject of H1 EMA20)
- inv=<ข้อความ <=48 ตัวอักษร>         (เงื่อนไขที่ทำให้ไอเดียนี้ผิด เช่น M15 close above 0.6760)
- rr=<ตัวเลข เช่น 2.0>                (R:R ตามแผน ถ้าไม่ได้คำนวณไว้ให้ละเว้น)
- sl=<ราคา> และ tp=<ราคา>             (ราคาจริงที่ใช้ ไม่ใช่ราคาโดยประมาณ)
- adr=IN หรือ adr=OUT                 (เป้าอยู่ใน/นอกกรอบ ADR ของวัน)

กฎเหล็ก:
1. ค่าในก้อนห้ามมี `;` และห้ามมี `]` — ถ้าข้อความต้องมี ให้เปลี่ยนคำหรือตัดให้สั้นลง
2. ` [STRUCT] ` (เว้นวรรคหน้าและหลัง) ปรากฏได้ครั้งเดียวเท่านั้น และต้องอยู่ท้ายสุดเสมอ
3. **ห้ามเดา** ค่าที่ไม่แน่ใจให้ละคีย์นั้นออก ค่าผิดแย่กว่าไม่มีค่า
4. ห้ามใช้ trailer ใน `learn --lesson` และห้ามใช้ใน `journal --decision HOLD --summary`
5. ลบ trailer ออกแล้วประโยคหน้าต้องยังอ่านรู้เรื่องและสมบูรณ์
6. ยาวรวมทั้งท่อนไม่เกิน 360 ตัวอักษร ถ้าเกินให้ตัดรายละเอียดในประโยค ไม่ใช่ตัดท้าย trailer

ตัวอย่างที่ถูก:

    H4/H1/M15 BEAR aligned; M15 swept H1 EMA20 (0.67413) & rejected bearish; SL at today_high (1.5x H1 ATR), TP 0.6708 (2.0R, within ADR) [STRUCT] bias=BEAR; tf=H4,H1,M15; trigger=M15 sweep+reject of H1 EMA20; inv=M15 close above 0.6760; rr=2.0; sl=0.67490; tp=0.67080; adr=IN

    H4/H1/M15 BEAR aligned; M15 EMA20 pullback zone 27040 with SL 27240 above H1 EMA20 (2.1R) [STRUCT] bias=BEAR; tf=H4,H1,M15; trigger=pullback into M15 EMA20 27040; rr=2.1

    H4/H1 BULL; M15 liquidity sweep low 1.99939 & reclaim above H1 EMA20/PDH; limit pullback retest above today_open, SL below today_low/H1 EMA50, TP 2.0058 (2.21R) [STRUCT] bias=BULL; tf=H4,H1; rr=2.21; sl=1.9968; tp=2.0058

ตัวอย่างที่ผิด:

    ... TP 0.6708 (2.0R, within ADR) [STRUCT] bias=BEAR; note=สวยมาก        <- คีย์เถื่อน (note) และภาษาไทยในค่า
    ... TP 0.6708 [STRUCT] bias=BEAR; inv=ปิดเหนือ 0.6760; tp=0.6708,0.6710  <- มี `;` ในค่า และค่า tp ไม่ใช่ราคาเดียว
    ... [STRUCT] bias=BEAR ... TP 0.6708                                    <- trailer ไม่ได้อยู่ท้ายสุด
```

### 3.1 English gloss (for the owner / reviewer)

The block asks the bot to keep its English sentence byte-identical in style and to append, **only when it truly
knows the values**, a ` [STRUCT] key=value; …` trailer with a fixed key set (`bias`, `tf`, `trigger`, `inv`, `rr`,
`sl`, `tp`, `adr`). It forbids guessing, forbids `;` and `]` inside values, forbids the marker anywhere but the end,
and forbids the trailer in lessons and HOLD summaries.

---

## 4. What changes on the dashboard if this is approved (`THESIS-2` delta)

Additive to the `THESIS-1` object; the contract file is bumped in the same change:

1. New field `Thesis.structured` — `null`, or an object holding only the keys actually present:
   ```json
   { "bias": "BEAR", "timeframes": ["H4","H1","M15"], "trigger": "M15 sweep+reject of H1 EMA20",
     "invalidation": "M15 close above 0.6760", "rr": 2.0, "sl": 0.6749, "tp": 0.6708, "withinAdr": true }
   ```
2. New field `Thesis.display` — the human part of `raw` **before** the marker. `raw` itself stays verbatim
   (trailer included) so nothing is lost; `clauses[].text + sep` then reconstructs `display`, and
   `display + " [STRUCT] " + trailer === raw`.
3. **Precedence:** an explicit `structured` value wins over the parsed equivalent, and the parsed value is kept
   alongside for audit. `structured` fields that disagree with the sentence are still rendered from the sentence —
   the sentence is what the bot *said*, the trailer is metadata.
4. `parse.mode` is unchanged; a thesis with a trailer and a valid sentence stays `"clauses"`.
5. A malformed trailer (unknown key, missing `=`, duplicated key, marker not at the end) is **ignored entirely** and
   the string parses exactly as `THESIS-1` would — no error state is introduced.

---

## 5. Rollout checklist (owner-gated)

- [ ] Owner approves the change to `mt5-ai-trader`'s prompt (this file is not a change request by itself).
- [ ] Renderer ships `THESIS-1` first and is verified against Appendix B of the contract.
- [ ] Renderer ships the `THESIS-2` delta (`structured` + `display`), verified with a synthetic trailer and with a
      malformed trailer.
- [ ] Only then, add section 3 to the live prompt.
- [ ] Observe 24 h: every new thesis must still concatenate back to its `raw`; no `mode: "raw"` regressions.
- [ ] Bump `version` to `THESIS-2` in `docs/thesis-contract.md` and note the date here.

**Nothing above is executed by writing this file.**
