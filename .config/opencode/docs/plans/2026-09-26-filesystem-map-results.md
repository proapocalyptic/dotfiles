# Filesystem map — results

Post-implementation measurement of the acceptance criteria from
`2026-09-26-filesystem-map.md`, against the baseline in
`2026-09-26-filesystem-map-baseline.md`.

## Call-count re-measurement

Q1, Q2, Q3 and Q5 replayed using **only** the `fsmap` tool:

| # | Question | Baseline calls | With map | Result |
|---|---|---|---|---|
| Q1 | What's in `~/src`? | 3 | shared with Q3 batch | 30 rows: repo name, `@` short HEAD, remote, branch, dirty flag |
| Q2 | Where are the Hyprland keybindings? | 3 | shared | 3 candidates immediately, each with its `role` pre-judged |
| Q3 | What does `task-block` do, what else exists? | 3 | shared | 40 executable scripts with usage lines |
| Q5 | What's eating disk in `~`? | 3 (1 hard timeout) | shared | 291.1G + top 8 consumers, **0 calls** (read from the digest) |

**3 `fsmap` calls total, versus 16 tool calls and one 120s `du` timeout.**

The gain is not really 16→3. It is that Q5 becomes *free* (it is inlined in
the overview) and Q1–Q3 become a single query each, with `role` and
"last commit" already resolved — so the follow-up calls the baseline needed
to disambiguate `.lua` from `.lua.bak` do not happen at all.

## Quality outcomes against the baseline's three failures

1. **Q3 inventory quality — fixed.** The baseline's failure was a
   `sed | grep ^#` heuristic that described 4 of 30 scripts, and lost slots to
   SPDX licence blocks and to a file that self-described as
   "CODED BY CLAUDE THE ROBOT". Extraction now skips licence blocks
   block-wise, prefers `usage:`/`Usage:` lines, and takes the first prose
   line only as a last resort. Of the 40 scripts listed, 30 carry a
   human-meaningful description.
2. **Q2 disambiguation — fixed by `role`.** `keybindings.lua`,
   `keybindings.conf` and `keybindings.lua.bak` come back as `signal`,
   `signal` and `artifact` respectively, so the live file is identifiable
   without opening any of them.
3. **Q5 `dua` incantation — fixed.** The digest carries
   `dua aggregate -f gb -x ~`, and the result is cached in the `meta` table,
   so a warm overview regenerates in ~0.06s.

## Q4 — still unanswerable, by design

The two Obsidian vaults (`~/Obsidian`, 136 md; `~/Documents/Obsidian`, 247 md)
remain indistinguishable from disk: distinct inodes, both with `.obsidian/`,
neither a symlink, sharing folder names. The map reports both as `signal` and
claims nothing about which is authoritative. This is the intended outcome —
the tool records what the filesystem can prove and stops there.

## Invariants verified

`fsmap-index.py check` on a fresh 61,879-row index:

```
signal files sampled : 4000 (0 missing)
.git leakage         : 0
pending notes        : 0 (cap 8)
durable notes        : 0
all invariants hold
```

Index: 61,879 rows, 87 descriptions, 16 git repos, 2.46s cold.
Overview: 2,091 chars, 32 lines, ~668 estimated tokens against an 800 budget.

## Known rough edges

- **Native runtime untested.** The tool is exercised through a Deno
  `node:sqlite` shim; no standalone `bun` exists on this machine, so the
  first real OpenCode load of `tools/fsmap.ts` is still unverified. The
  schema-v2 `paths.is_exec` column is also assumed rather than checked, so an
  index built before the migration will need a `fsmap refresh` first.
- **Keybinding needs a reload path.** Hyprland registers Lua bindings at
  session start. `hyprctl reload` re-reads the config but does not re-execute
  `hyprland.lua`, so `SUPER+ALT+SHIFT+N` is not live until the compositor
  next starts. Verified in-file: syntax-clean, and its modmask (69 =
  Super+Alt+Shift) is absent from `hyprctl binds` until then.

## Fixed during verification

- **`fsmap-notes review` promoted everything.** The picker printed a
  "d reject" prompt and then tested the returned line for a `d`, but fuzzel
  and fzf both echo the selected entry verbatim, so that test could never
  match. Rewritten as a plain per-note question (`p`/`r`/`s`/`q`) with no
  external picker dependency; the fake keybinding and the now-unused
  `picker_available`/`subprocess` code are gone. Verified over a real pty
  for all four answers, including that `q` on the first note changes nothing.
- **`age_days` crashed on a non-integer `created_at`.** Both writers agree on
  integer epoch seconds, but `list` is the non-interactive fallback for the
  systemd nudge service, so a stray value raised a traceback into the journal
  daily. Now degrades to age 0 instead.
- **Dangling `Documentation=man:`** in both unit files pointed at man pages
  that do not exist, which `systemd-analyze verify` flagged. Removed; the
  units now verify clean.
- **Review prompt advertised a key that did nothing** — see above.

## Verified end state

```
61,879 rows · 87 descriptions · 16 git repos · 2.46s cold build
overview: 2,091 chars, 32 lines, ~668 est. tokens (budget 800) → OK
check:    4000 signal files sampled, 0 missing, 0 .git leakage → all invariants hold
timers:   fsmap-index 04:17 daily, fsmap-nudge 09:23 daily, both enabled
RPROMPT:  0 pending → empty · 3 → three dots · 10 → capped at 8 · absent DB → silent, rc 0
notes:    promote / reject-with-reason / skip / quit / expire all exercised
```
