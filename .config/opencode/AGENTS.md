# Rules

- Never create, modify, or close GitHub issues or pull requests without explicit user instruction. Read-only GitHub operations (search, list, view) are always fine.
- If a command requires sudo, just say so and present the command. Do not waste tokens trying to invent a sudoless workaround. The user will run sudo commands themselves if they make sense.
- Stick to XDG directory conventions when possible (e.g., `$XDG_CONFIG_HOME`, `$XDG_DATA_HOME`, `$XDG_STATE_HOME`, `$XDG_CACHE_HOME`). Prefer environment variables over hardcoded paths like `~/.config`.

# Filesystem map

There is a prebuilt index of this machine at `~/.local/share/opencode/fsmap/index.db`, queried through the `fsmap` tool. **Prefer it over `ls`, `find`, `du`, `tree` and friends for discovery** — it is orders of magnitude cheaper and already knows what is bulk, what is vendored, and what is dormant. A generated orientation digest lives at `~/.config/opencode/map/overview.md` and is the right starting point for "what is on this machine?".

- Actions: `where <glob>` (role-filterable), `what <path>`, `find <terms>`, `repos`, `scripts`, `changed [days]`, `stale [days]`, `refresh`, `note <path> <text>`.
- Three tiers of trust, do not blur them:
  - **Shape is authoritative** — directory layout, file counts, which paths exist, git remote/HEAD.
  - **Content is a lead** — the `description` fields are heuristics scraped from file headers and command usage. Verify before acting on one.
  - **Live state is never cached** — which file is actually loaded, current HEAD, running processes, whether a daemon is up. Always read that fresh.
- `role=stale` means untouched for 90+ days. It is *evidence of disuse, not proof*: write-once configs of live apps land there too. Never propose deleting anything on the strength of `stale` alone.
- `role=artifact` means build/vendor (`node_modules`, `target`, `dist`, `.git`); `role=noise` means bulk media you should not search; `role=unindexed` means present but deliberately not walked.
- A glob is matched as a **substring** (`hypr*` finds anything containing `hypr`), because indexed paths are absolute and an anchored pattern would never match.
- Record durable facts about a path with `fsmap note <path> <text>`. It goes to a **pending** queue, not the durable map. Only the user promotes it, so never state a queued note as established fact.

Rebuild with `fsmap refresh` (or `fsmap-index.py build`) after large filesystem changes. A systemd timer reindexes daily at 04:17.

# Working style

- I prefer to be directly involved in the technical details of a task. Rather than vaguely describing an outcome and having you figure out the implementation, I want to discuss approaches, trade-offs, and specifics before you proceed.
- When multiple good options exist for a decision, ask me which I prefer. This applies to ambiguity and qualitative choices — not to situations where there is an obvious best answer. Don't second-guess clear decisions; only surface choices that genuinely warrant my input.
- I use generative AI as a learning tool rather than as a magic button that completes tasks. Engage with me accordingly — explain reasoning, surface alternatives, and help me understand the work.
- I prefer any AI generated code that is being saved to the file system to be clearly commented. 
- I have a solid high-level understanding of programming concepts and a background in symbolic logic, but my knowledge of actual programming syntax is my biggest bottleneck. Lean into that when explaining things.
- For extremely basic tasks, no explanations are required. Sometimes I do just want a robot to do the busywork.

# Per-agent files

Check the `agents/` subdirectory for per-agent instructions before making changes to this global file. Agent-specific conventions go there rather than here.
