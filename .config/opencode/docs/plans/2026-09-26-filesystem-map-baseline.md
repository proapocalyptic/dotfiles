# Baseline: filesystem exploration without a map

**Measured:** 2026-09-26
**Method:** each question answered the way an agent with no prior map would —
start broad, notice the answer is insufficient, refine. Counted *tool
invocations*, not reasoning steps. A call that failed or timed out counts.

## Results

| # | Question | Calls | Outcome |
|---|---|---|---|
| Q1 | What's in `~/src`? | 3 | 15 opaque names → language+README → git remote/branch/last-commit/dirty. Resolved that `hyprsysteminfobak` shares origin *and* last-commit date with `hyprsysteminfo` (a copy-fork, both dirty). |
| Q2 | Where are the Hyprland keybindings? | 3 | Found `keybindings.lua` among 3 plausible candidates (`.bak`, `input.lua`), then confirmed `require("hyprland.keybindings")` at `hyprland.lua:10` and that `input.lua` holds 0 binds. |
| Q3 | What does `task-block` do, and what other scripts exist? | 3 | Single script: fine (1 call, 20-line head). **Inventory: failed quality.** A `sed -n '2,6p' \| grep ^#` heuristic described 4 of 30 scripts. Refined heuristic reached 30%, but SPDX license headers won 4 slots and `small-terminal-header.sh` yielded "CODED BY CLAUDE THE ROBOT". |
| Q4 | Which Obsidian directory is the vault? | 4 | **Unresolved — and not resolvable from disk.** Both `~/Obsidian` (136 md) and `~/Documents/Obsidian` (247 md) have `.obsidian/`, different inodes, neither a symlink, sharing folder names (`Fermentation logs`, `Information Quilt`, `PureWriter`). `~/Documents/dox` is not a vault. |
| Q5 | What's eating disk in `~`? | 3 | First call `du -sh ~` **timed out at 120s**. `dua` has no `-s` flag (needs the `aggregate` subcommand). Resolved via `dua aggregate -f gb -x`: 291G total. |

**Total: 16 tool calls, 1 hard timeout, 1 question the filesystem cannot answer.**

## Why Q4 is the important one

Q1, Q2, Q3 and Q5 are all *derivable* — a map can hold their answers.
Q4 is not. The filesystem can prove two vaults exist; only the user knows
which is authoritative. This is the case the pending→durable note pipeline
exists for, and it is the justification for the manual review gate rather
than auto-promotion.

Note also that the plan document initially asserted, unverified, that
`~/Documents/Obsidian` was the vault and `~/Obsidian` was not. Measurement
refuted it. That is the "advisory for content" tier earning its name.

## Findings that shaped the implementation

1. **Description extraction is structurally capped at ~30%.** The
   `nvim-open*` family, `grist`, `new-note` and `menu-settings-toggle` carry
   no purpose comment at all — only `new-note`'s body (`obsidian`, `hyprctl
   dispatch`) reveals what it does. Fallback summary must be
   *derived commands used*, not guessed prose.
2. **SPDX licence blocks need block-level skipping**, not line filtering:
   the Espressif scripts defeat line filters because line 2 of the licence
   block reads as prose.
3. **`dua` needs `dua aggregate`, not `-s`.** Recorded in the map so the
   right incantation is already known.
4. **Disk usage is a high-value, zero-call answer.** 291G with the top ten
   consumers is a fact worth inlining in the digest.

## Re-measurement (with map)

Recorded after implementation, in `docs/plans/2026-09-26-filesystem-map-results.md`.
