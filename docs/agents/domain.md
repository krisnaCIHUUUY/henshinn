# Domain Docs

How the engineering skills should consume this repo's domain documentation when
exploring the codebase. Layout: **single-context** — one project, one set of
decision records.

## Before exploring, read these

- **`AGENTS.md`** at the repo root — tech stack, folder structure, and the code
  conventions every change must follow. Read this first; it is not optional.
- **`docs/keputusan-arsitektur.md`** — this repo's ADR file. Read the ADRs that
  touch the area you are about to work in (DB, PIN, stock, and money code in
  particular). It records decisions you cannot infer from the code.
- **`docs/henshin_prd.md`** — scope and business rules, including what is
  deliberately out of scope (PRD §1.4, mirrored in `AGENTS.md` §6).
- **`docs/progress.md`** — what is already built, and the tech-debt table.
- **`CONTEXT.md`** at the repo root — does not exist yet. If it appears later,
  read it as the glossary.

If any of these files don't exist, **proceed silently**. Don't flag their
absence; don't suggest creating them upfront. The `/domain-modeling` skill
(reached via `/grill-with-docs` and `/improve-codebase-architecture`) creates
them lazily when terms or decisions actually get resolved.

## ADRs live in one file, not `docs/adr/`

This repo keeps every architecture decision in a single file,
`docs/keputusan-arsitektur.md`, as `## ADR-NNN` sections numbered sequentially.
**Do not create `docs/adr/`** and do not split the file — `AGENTS.md` §5 and the
cross-links inside the ADRs depend on the current shape. A new decision takes
the next free number; never renumber an existing one.

```
/
├── AGENTS.md                       ← conventions an agent must follow
├── docs/
│   ├── keputusan-arsitektur.md     ← ALL ADRs, `## ADR-NNN` sections
│   ├── henshin_prd.md              ← scope + business rules
│   ├── implementasi.md             ← step plan
│   └── progress.md                 ← what is done
└── lib/                            ← feature-per-folder clean architecture
```

## Use the project's vocabulary

The docs and the code are written with Indonesian domain terms (`transaksi`,
`void`, `stok`, `riwayat`, `laporan`, `laba kotor`, `omzet`). When your output
names a domain concept — an issue title, a refactor proposal, a hypothesis, a
test name — use the term the code and docs already use. Don't translate it to an
English synonym, and don't introduce a second word for a concept that already
has one.

If the concept you need has no term yet, that's a signal — either you're
inventing language the project doesn't use (reconsider) or there's a real gap
(note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than
silently overriding:

> _Bertentangan dengan ADR-011 (setiap perubahan stok menulis satu baris
> `stock_movements`) — tapi layak dibuka ulang karena…_

An operational rule that an agent must follow *while writing code* belongs in
`AGENTS.md` §3 or §4 as well as in an ADR — an ADR alone is too deep to be
found in time (see ADR-025).
