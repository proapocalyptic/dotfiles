# Plan Document Reviewer Prompt Template

Use this template to dispatch an independent plan reviewer. Self-review is still the default gate — dispatch this on plans of **more than 6 tasks**, or when a single task would need more than one reviewable deliverable. See [Self-Review](SKILL.md#self-review).

**If you cannot dispatch this** — because you are yourself a subagent, or for any other reason — do not perform the review in your own place. Mark the plan `**Review status:** UNREVIEWED` and hand it back. An author re-reading their own plan confirms what they already believed; the categories below are only worth running when a second pair of eyes brings different assumptions.

**Purpose:** catch spec drift, boundary problems, and buildability gaps that the plan's author is blind to.

**Dispatch after:** the complete plan is written, and self-review has already been run and its findings fixed.

```
task(
  description: "Review plan document",
  subagent_type: "general",
  prompt: |
    You are a plan document reviewer. Verify this plan is complete and ready
    for implementation. You did not write it — read it skeptically.

    **Plan to review:** [PLAN_FILE_PATH]
    **Spec for reference:** [SPEC_FILE_PATH]

    ## What to Check

    | Category | What to Look For |
    |----------|------------------|
    | Completeness | TODOs, placeholders, incomplete tasks, missing steps |
    | Spec Alignment | Every spec requirement maps to a task; no scope creep |
    | Task Decomposition | One reviewable deliverable per task; setup folded into the task that needs it |
    | Interfaces Integrity | Every signature a task consumes is produced by an earlier task, spelled identically |
    | Type Consistency | Names, types, and property names match across tasks |
    | Buildability | Could an engineer follow any task without getting stuck? Real paths, runnable commands |

    ## Calibration

    **Only flag issues that would cause real problems during implementation.**
    An implementer building the wrong thing, referencing a name that does not
    exist, or getting stuck is an issue. Minor wording, stylistic preferences,
    and "nice to have" suggestions are not.

    Approve unless there are serious gaps — missing spec requirements,
    contradictory steps, placeholder content, mismatched names, or tasks so
    vague they can't be acted on.

    ## Output Format

    ## Plan Review

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [Task X, Step Y]: [specific issue] - [why it matters for implementation]

    **Recommendations (advisory, do not block approval):**
    - [suggestions for improvement]
)
```

**Reviewer returns:** Status, Issues (if any), Recommendations. If Status is Issues Found, fix and re-run self-review — the reviewer's findings do not replace it.
