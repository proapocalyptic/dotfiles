# Plan: Local Filesystem Map

**Date:** 2026-09-26
**Status:** approved, in progress

## Goal

Give opencode a durable, referenceable map of the local filesystem so it stops
running exploratory commands (`ls`, `find`, `du`, guess-and-check greps) to
re-derive facts it has already derived. Two distinct wastes to remove:

1. **Per-session exploration** — opencode spends turns working out *what to
   search for* before it can search.
2. **Cross-session amnesia** — the same structural facts are rediscovered in
   every new session.

The map must also be explicit about **where not to look**. A map's job is as
much about pruning the search space as describing it.

## Global Constraints

These are the load-bearing assumptions. Violating them makes the map actively
harmful rather than merely useless.

- **Three-tier validity.** Facts decay at different rates, so the map must
  declare which tier each claim belongs to:
  - *Shape* (does this directory exist, what is in it) — decays over weeks.
    **Authoritative.**
  - *Content* (what a script does, what a repo's remote is) — decays over
    months. **Advisory**; verify before acting on it.
  - *Live state* (which config file is currently loaded, current git HEAD,
    current process state) — decays in minutes. **Never cached. Always read
    live.**
- **A stale map is worse than no map**, because opencode trusts it. Mitigations:
  a `generated_at` stamp on every generated artefact, plus the tier rules in
  `AGENTS.md`.
- **Annotations are human-authored facts of record.** opencode proposes; the
  user promotes. opencode never writes to the durable set directly.
- **Unbounded queues die.** The pending-note queue is hard-capped and expires.
- **Path matching is glob/substring, not full-text.** FTS5 tokenizes on word
  boundaries, which destroys hyphenated and dotted identifiers
  (`hyprsysteminfobak`, `nvim-open-nconfig`). FTS5 is reserved for genuinely
  prose content (script descriptions).

## Architecture

Three layers, deliberately separated by cost and latency profile.

| Layer | Mechanism | Cost | Staleness |
|---|---|---|---|
| **L0** Address book | `references` in `opencode.jsonc` | ~free | never — paths are facts |
| **L1** Orientation digest | `map/overview.md`, ~800 tokens, in `instructions[]` | every session | weeks |
| **L2** Detail index | SQLite + `tools/fsmap.ts`, 72k rows | on demand only | weeks |
| **L3** Annotations | `map/notes/durable.md` | tiny | never |

L0 gives opencode *addresses* (and auto-clears the external-directory
permission boundary). L1 gives it *shape* cheaply enough to always be present.
L2 holds everything too big to inline, reachable only by query. L3 holds facts
that must not be regenerated because they are not derivable from the filesystem.

## Tech Stack

- **Indexer:** Python 3, `sqlite3` stdlib. FTS5 confirmed present (SQLite 3.53.4).
- **Tool:** TypeScript via `@opencode-ai/plugin`, querying with Bun's built-in
  `bun:sqlite`. No new runtime dependency.
- **Queue CLI + TUI:** Python 3 driving `fuzzel` (`/usr/local/bin/fuzzel`,
  built from `~/src/fuzzel`). `fzf` 0.74.4 is the fallback.
- **Scheduling:** systemd user timers, matching the existing
  `speaker-guard.service` house style (`Type=oneshot`, `WantedBy=default.target`).
- **Notification:** `notify-send` → `mako` (already running).

## Spec

### Files created

| Path | Role |
|---|---|
| `lib/fsmap-index.py` | walker, role classifier, git enrichment, description extractor |
| `lib/fsmap-notes` | queue CLI, cap/expiry/rejection memory, `fuzzel` TUI |
| `tools/fsmap.ts` | opencode custom tool (auto-discovered) |
| `map/overview.md` | **generated** orientation digest |
| `map/notes/durable.md` | human-promoted annotations (fact of record) |
| `map/notes/pending.md` | human-readable mirror of `notes_pending` |
| `map/notes/rejected.md` | rejection log with reasons |
| `command/fsmap-review.md` | slash command for in-band review |
| `systemd/user/fsmap-index.{service,timer}` | scheduled reindex |
| `systemd/user/fsmap-nudge.{service,timer}` | scheduled review reminder |
| `~/.local/bin/fsmap`, `~/.local/bin/fsmap-notes` | PATH symlinks |

### Files modified

`opencode.jsonc` (`instructions[]`, `references`, `permission.external_directory`)
· `AGENTS.md` (filesystem-map section) · `package.json` (plugin 1.14.48 → 1.18.32)
· `.zshrc` line 41 (pending indicator prepended to the clock `RPROMPT`)
· `hyprland/keybindings.lua` (review binding)

### XDG placement

| Kind | Path |
|---|---|
| Database | `$XDG_DATA_HOME/opencode/fsmap/index.db` |
| Mutable state (snooze, tally) | `$XDG_STATE_HOME/opencode/fsmap/` |

### Schema

```sql
meta(key, value)                    -- generated_at, roots, counts, schema_version
paths(path PK, root, name, parent, depth, is_dir, size, mtime,
      ext, is_git, git_remote, git_head, role)
descriptions(path PK, summary, source)          -- FTS5 target
notes(id PK, path, text, created_at, session, promoted_at)
notes_pending(id PK, path, text, created_at, session)
rejected(key PK, reason, at)
```

### Roles

`role ∈ {signal, artifact, noise, stale}`

- `signal` — real content worth mapping.
- `artifact` — build output: `.git/`, `node_modules/`, `*.o`, `build/`,
  `Testing/`, `CMakeCache.txt`, `__pycache__/`.
- `noise` — `core.*`, `steam-*.log`, `*.deb`, `*.zip`, `*.webm`, `~/Downloads`.
- `stale` — **derived, not hardcoded**: a config dir whose newest descendant
  mtime exceeds 90 days, minus a short known-live list. Self-updating: flags
  abandoned desktops on its own, and re-classifies a dir if it becomes active
  again. The known-live list is the only hand-maintained part.

### Index scope

Five curated roots walked at full depth, plus a depth-1 sweep of `$HOME` to
record top-level noise (core dumps, stray archives) by name only.

Roots: `~/src`, `~/.dotfiles`, `~/Documents`, `~/Obsidian`, `~/.config`,
plus `~/.local/bin` (89 scripts, high metadata value).

`~/.dotfiles` is a non-bare git repo whose working tree *is* its own git
internals — the classifier must mark `.git/**` as `artifact` or the object
database gets indexed.

### Tool surface

`where <glob>` · `what <path>` · `find <substring>` · `changed <N days>` ·
`repos` · `scripts` · `stale` · `refresh` · `note <path> <text>`

### Notes queue

```
count | list | review | nudge | promote <id> | reject <id> <why>
note <path> <text> | snooze <dur> | expire | tally
```

Four rules keep review cheap enough that it actually happens:

1. **Live verification in the TUI** — path exists, still a git repo, HEAD
   unchanged *since the note was written*, queried at review time. Most notes
   become judgeable at a glance.
2. **Aging flags stale rows** at >14 days, since most old pending notes
   describe something that has since changed.
3. **Hard cap at 8 pending.** Past that `note` refuses and instructs opencode
   to surface the fact verbally in-session, and to consider `AGENTS.md` as the
   correct home for it.
4. **Rejection memory** — `rejected(key, reason, at)`, checked before
   proposing. Without it the gate becomes a rejection treadmill: the same
   wrong note returns every month forever.

**Expiry:** at 30 days a pending note moves to `rejected` with reason
`expired` and increments a tally surfaced in `overview.md`. Visible decay is
the signal: if the expiry tally outpaces promotions, the note-producing side
is too eager.

### Trigger ladder

| Tier | Mechanism | Character |
|---|---|---|
| 0 | `pending: N (M expired)` in `overview.md` + `AGENTS.md` instruction | free, weakest delivery |
| 1 | `RPROMPT` count-dot at `.zshrc:41` | ambient, silent at 0, unscrollable |
| 3 | systemd timer → `notify-send` → mako, gated `count ≥ 3` && not snoozed | active escalation, survives terminal closure |

Delivery scales with neglect rather than being constant.

## Acceptance Criteria

1. Five representative questions answered in **strictly fewer** tool calls with
   the map than the recorded baseline.
2. `overview.md` asserted **≤ 800 tokens** by a test, not by eye.
3. Full index build **< 3s** for 72k rows, measured.
4. `note` refuses past 8 pending; expiry and rejection memory verified by test.
5. `fsmap` never reports a `signal` path that does not exist.
