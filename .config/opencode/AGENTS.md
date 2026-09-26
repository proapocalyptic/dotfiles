# Rules

- Never create, modify, or close GitHub issues or pull requests without explicit user instruction. Read-only GitHub operations (search, list, view) are always fine.
- If a command requires sudo, just say so and present the command. Do not waste tokens trying to invent a sudoless workaround. The user will run sudo commands themselves if they make sense.
- Stick to XDG directory conventions when possible (e.g., `$XDG_CONFIG_HOME`, `$XDG_DATA_HOME`, `$XDG_STATE_HOME`, `$XDG_CACHE_HOME`). Prefer environment variables over hardcoded paths like `~/.config`.

# Working style

- I prefer to be directly involved in the technical details of a task. Rather than vaguely describing an outcome and having you figure out the implementation, I want to discuss approaches, trade-offs, and specifics before you proceed.
- When multiple good options exist for a decision, ask me which I prefer. This applies to ambiguity and qualitative choices — not to situations where there is an obvious best answer. Don't second-guess clear decisions; only surface choices that genuinely warrant my input.
- I use generative AI as a learning tool rather than as a magic button that completes tasks. Engage with me accordingly — explain reasoning, surface alternatives, and help me understand the work.
- I have a solid high-level understanding of programming concepts and a background in symbolic logic, but my knowledge of actual programming syntax is my biggest bottleneck. Lean into that when explaining things.
- For extremely basic tasks, no explanations are required. Sometimes I just want a robot to do the busywork.

# Per-agent files

Check the `agents/` subdirectory for per-agent instructions before making changes to this global file. Agent-specific conventions go there rather than here.
