---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. TDD, with a commit per task.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** this skill *writes* plans; it does not create worktrees. If execution will happen in an isolated worktree, create it at execution time.

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

**The plan is a file, always.** Write it to disk even when the request sounds casual, even when the user says "keep it tight" or "just tell me what to do," and even when it feels small enough to do inline. A plan delivered only as chat text is not a plan — it cannot be reviewed, handed to a subagent, or executed task-by-task. If the user genuinely wants no document, say so explicitly and let them override; don't decide that for them.

**Don't block on open questions.** If the spec is ambiguous, pick the most reasonable reading, write it into the plan as a stated assumption, and keep going. A plan delivered with two assumptions flagged and ready is more useful than a question. Reserve blocking for a decision that would invalidate the whole approach — a missing spec, or a requirement that contradicts another.

**If a plan already exists at that path**, don't silently overwrite it and don't silently ignore it. Read it, then say which it is: superseded (and rewrite), still current (and leave it alone), or a different scope (and write alongside it under a distinct name).

## Scope Check

If the spec covers multiple independent subsystems, it should have been split into one spec per subsystem. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- Prefer smaller, focused files over large ones that do too much. Focused files are easier to review, easier to change, and their edits are more reliable.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a
fresh reviewer's gate. When drawing task boundaries: fold setup,
configuration, scaffolding, and documentation steps into the task whose
deliverable needs them; split only where a reviewer could meaningfully
reject one task while approving its neighbor. Each task ends with an
independently testable deliverable.

## Step Granularity

**Each step is one action, roughly 2–5 minutes** — write the failing test, run it to confirm it fails, implement the minimum to pass, run the tests, commit. The [Task Structure](#task-structure) template below shows the canonical sequence; follow it rather than inventing your own step decomposition.

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** this plan is executed task-by-task. Each implementer
> receives **only their own task**, so anything they need from a neighboring task
> must appear in that task's **Interfaces** block. Executors have file edits, bash,
> and test tooling. **Progress is tracked by the primary agent via `todowrite` —
> an implementer subagent cannot update the todo list itself.** Checkbox syntax
> below is for human reading, not machine tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Spec:** [path to the spec/design doc this plan implements — the plan
argues from the spec, so the spec travels with it; executors read both]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself, and it is the default gate — every plan gets it.

**1. Spec coverage:** skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps, and add a task for each.

**2. Placeholder scan:** search your plan for the failure patterns listed under [No Placeholders](#no-placeholders) — `TBD`, `implement later`, "add appropriate error handling", "write tests for the above" without test code, "similar to Task N", steps that describe without showing, and references to types or functions no task defines. Fix every hit.

**3. Type consistency:** do the types, method signatures, and property names in later tasks match what you defined in earlier ones? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

**4. Task boundaries:** does each task have one clear deliverable a reviewer could reject independently of its neighbors? Setup, config, and scaffolding folded into the task that needs them is correct; a task bundling two reviewable outcomes is not.

**5. Buildability:** could an engineer who has never seen this codebase follow Task 1 without getting stuck? Every file path real, every Interfaces entry defined by an earlier task, every command runnable as written.

If you find issues, fix them inline — no need to re-review, just fix and move on.

### When to dispatch a reviewer instead

Self-review is the gate, but on a **plan of more than 6 tasks** — or any plan where a single task would need more than one reviewable deliverable — dispatch an independent reviewer as well. A second pass catches spec drift and boundary problems that are invisible to you precisely because you just wrote them.

Use the template in [plan-document-reviewer-prompt.md](plan-document-reviewer-prompt.md): give it the plan path and the spec path, and hold it to the calibration clause there — approve unless there are gaps that would actually stall an implementer. Don't act on stylistic suggestions.

**If you genuinely cannot dispatch a reviewer, the plan is UNREVIEWED — say so in the document and in your reply. Do not review it yourself in its place.** Re-reading your own plan catches typos; it does not catch the assumption you were wrong about, which is the only thing the reviewer is for. A self-review wearing a reviewer's label is worse than no review, because it manufactures confidence. Write `**Review status:** UNREVIEWED — no independent reviewer available` at the top of the plan and let the human decide whether to proceed.

## Execution Handoff

After saving the plan, offer the choice:

**"Plan complete and saved to `docs/plans/<filename>.md`. Two execution options:**

**1. Fresh subagent per task (recommended)** — I dispatch a new subagent for each task with `subagent_type: general`, and review the diff between tasks. Fresh context per task keeps implementers honest and makes review tractable.

**2. Inline execution** — I work the tasks in this session, batching with checkpoints for your review. Faster for small plans, but context accumulates across tasks.

**Which approach?"**

**Two constraints that make either path work:**

- **The primary agent owns progress tracking.** A `general` subagent's tools are file edits, bash, read, grep, glob, web tools, and the GitHub tools — it does **not** have `todowrite`, and it does **not** have `task`. Create a todo per task up front, and mark it complete yourself after each dispatch returns. Don't ask an implementer to tick off steps; it has no way to.
- **An implementer sees only its own task.** That is the point of a fresh context, but it means the **Interfaces** block is load-bearing: if Task 4 calls something Task 2 produces, Task 4 must state the exact name and signature. A missing Interfaces entry is a stalled implementation, not a minor doc gap.

**Reviewer dispatch is the primary's job too**, for the same reason: a subagent cannot dispatch a subagent. If *you* are running as a subagent, you cannot perform an independent review — hand the plan back to the primary and say a review is required.

**If a plan will be executed repeatedly**, a dedicated subagent in `~/.config/opencode/agents/plan-executor.md` (a markdown file with `mode: subagent`) makes the per-task dispatch repeatable without restating the constraints each time.
