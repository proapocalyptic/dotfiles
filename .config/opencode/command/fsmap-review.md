---
description: Review unreviewed filesystem-map annotations
agent: build
---

Present the pending annotation queue and let the user promote or reject each
one. Do NOT batch-approve and do not decide on the user's behalf — the entire
point of the queue is that nothing becomes durable context without a human
saying yes.

Steps:

1. Show the queue. Run `fsmap-notes list`. If it reports an empty queue, say
   so in one line and stop; do not go looking for work.

2. Present each note with everything needed to judge it:
   - the annotation text and its path
   - `fsmap what <path>` for the surrounding structure
   - whether the path's `role` is `stale` — a note on a `stale` path deserves
     more scepticism, not less, because "this is dead code" is the kind of
     claim that ages badly
   - how old the note is; past 14 days it is worth re-deriving from the current
     filesystem rather than trusting what a past session saw

3. For each note, ask the user to promote or reject it, and say what each
   outcome means. Then carry it out:
   - promote: `fsmap-notes promote <id>` — becomes durable, and will be shown
     by `fsmap what` from now on
   - reject: `fsmap-notes reject <id> "<reason>"` — the reason is required in
     spirit even though the CLI allows omitting it, because it is what stops
     the same wrong note being proposed again in a later session

4. If a note is factually wrong rather than unwanted, say so and offer to
   `fsmap refresh` so the map matches reality.

Rules:

- Never state a pending note as established fact. It is unconfirmed until the
  user promotes it.
- Never promote on the user's behalf, even when a note looks obviously true.
- After the queue is empty, report the final tallies (`fsmap-notes tally`) and
  stop. Do not re-index or start unrelated work.
