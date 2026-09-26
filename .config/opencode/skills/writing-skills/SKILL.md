---
name: writing-skills
description: Use when creating new skills, editing existing skills, or verifying skills work before deployment
---

# Writing Skills

## Overview

**Writing skills IS Test-Driven Development applied to process documentation.**

**Personal skills live in your runtime's skills directory:**

| Runtime | Location |
|---|---|
| **opencode** (this skill's home) | `~/.config/opencode/skills/<name>/SKILL.md` |
| Claude Code | `~/.claude/skills/<name>/SKILL.md` |
| Codex, Copilot CLI, Gemini CLI | `~/.agents/skills/<name>/SKILL.md` |

You write test cases (pressure scenarios with subagents), watch them fail (baseline behavior), write the skill (documentation), watch tests pass (agents comply), and refactor (close loopholes).

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

**REQUIRED BACKGROUND:** The RED-GREEN-REFACTOR cycle from TDD — write a failing test, watch it fail, write the minimal passing change, then refactor while staying green. This skill adapts that cycle to process documentation: the pressure scenario is the test, the skill document is the production code, and a rationalization is a regression.

**Official guidance:** The Agent Skills specification at [agentskills.io/specification](https://agentskills.io/specification) defines the portable `SKILL.md` format. Where opencode's rules are stricter, opencode's rules win — see [Frontmatter](#frontmatter) below.

## What is a Skill?

A **skill** is a reference guide for proven techniques, patterns, or tools. Skills help future agents find and apply effective approaches.

**Skills are:** Reusable techniques, patterns, tools, reference guides

**Skills are NOT:** Narratives about how you solved a problem once

## TDD Mapping for Skills

| TDD Concept | Skill Creation |
|-------------|----------------|
| **Test case** | Pressure scenario with subagent |
| **Production code** | Skill document (SKILL.md) |
| **Test fails (RED)** | Agent violates rule without skill (baseline) |
| **Test passes (GREEN)** | Agent complies with skill present |
| **Refactor** | Close loopholes while maintaining compliance |
| **Write test first** | Run baseline scenario BEFORE writing skill |
| **Watch it fail** | Document exact rationalizations agent uses |
| **Minimal code** | Write skill addressing those specific violations |
| **Watch it pass** | Verify agent now complies |
| **Refactor cycle** | Find new rationalizations → plug → re-verify |

The entire skill creation process follows RED-GREEN-REFACTOR.

## When to Create a Skill

**Create when:**
- Technique wasn't intuitively obvious to you
- You'd reference this again across projects
- Pattern applies broadly (not project-specific)
- Others would benefit

**Don't create for:**
- One-off solutions
- Standard practices well-documented elsewhere
- Project-specific conventions (put in your instructions file)
- Mechanical constraints (if it's enforceable with regex/validation, automate it—save documentation for judgment calls)

## Skill Types

### Technique
Concrete method with steps to follow (condition-based-waiting, root-cause-tracing)

### Pattern
Way of thinking about problems (flatten-with-flags, test-invariants)

### Reference
API docs, syntax guides, tool documentation (office docs)

## File Organization

All skills share one flat, searchable namespace: `skills/<skill-name>/SKILL.md`, where `<skill-name>` must equal the `name` in the frontmatter.

```
skills/
  skill-name/
    SKILL.md              # Main reference (required)
    supporting-file.*     # Only if needed
    scripts/              # Executable tools, if any
```

Pick the shape to fit the content:

| Shape | Layout | When |
|---|---|---|
| Self-contained | `SKILL.md` only | Everything fits inline; no heavy reference needed |
| With reusable tool | `SKILL.md` + `example.ts` | The tool is reusable code, not just narrative |
| With heavy reference | `SKILL.md` + `pptxgenjs.md` + `scripts/` | Reference material too large to inline |

**Separate files for:** heavy reference (100+ lines of API docs or syntax) and reusable tools (scripts, utilities, templates).

**Keep inline:** principles and concepts, code patterns under ~50 lines, and everything else.

## Frontmatter

opencode recognizes exactly five fields. Unknown fields are silently ignored.

| Field | Required | Notes |
|---|---|---|
| `name` | yes | See constraints below |
| `description` | yes | 1–1024 characters |
| `license` | no | e.g. `MIT` |
| `compatibility` | no | ≤500 chars; environment requirements |
| `metadata` | no | string→string map |

For the portable cross-runtime format (which adds experimental `allowed-tools`), see [agentskills.io/specification](https://agentskills.io/specification).

**`name` constraints — violating any of these makes opencode skip the skill with no error:**

- 1–64 characters
- Lowercase letters, digits, and single hyphens only: `^[a-z0-9]+(-[a-z0-9]+)*$`
- No leading, trailing, or consecutive hyphens
- **Must match the parent directory name.** Rename the folder without editing the frontmatter and the skill silently stops loading.

**`description`:**
- Third-person, describes ONLY when to use (NOT what it does)
- Start with "Use when..." to focus on triggering conditions
- Include specific symptoms, situations, and contexts
- **NEVER summarize the skill's process or workflow** (see SDO section for why)
  - Keep under 500 characters if possible

## SKILL.md Structure

```markdown
---
name: skill-name-with-hyphens
description: Use when [specific triggering conditions and symptoms]
---

# Skill Name

## Overview
What is this? Core principle in 1-2 sentences.

## When to Use
[Small flowchart or decision list IF the choice is non-obvious]

Bullet list with SYMPTOMS and use cases
When NOT to use

## Core Pattern (for techniques/patterns)
Before/after code comparison

## Quick Reference
Table or bullets for scanning common operations

## Implementation
Inline code for simple patterns
Link to file for heavy reference or reusable tools

## Common Mistakes
What goes wrong + fixes
```


## Skill Discovery Optimization (SDO)

**Critical for discovery:** Future agents need to FIND your skill

### 1. Rich Description Field

**Purpose:** your agent reads the description to decide whether to load the skill. Make it answer: "Should I read this right now?"

**CRITICAL: description = when to use, not how the skill works.**

**Why:** testing showed that when a description summarizes the workflow, an agent follows the *description* instead of reading the skill. A description reading "code review between tasks" produced exactly ONE review, even though the skill's own flowchart specified two (spec compliance, then code quality). Rewritten as "Use when executing implementation plans with independent tasks," the agent read the flowchart and did both. **Workflow summaries create a shortcut; the body becomes documentation agents skip.**

**Reconciling with the spec:** the Agent Skills spec says a description should cover what the skill does *and* when to use it. Both are satisfiable — name the **subject**, never the **method**. "Use when creating skills" names the subject. "Dispatches a subagent per task with code review between tasks" summarizes the method. Subject is fine; method is the shortcut.

| ❌ Bad | Why |
|---|---|
| `Use when executing plans - dispatches subagent per task with code review between tasks` | Summarizes workflow |
| `Use for TDD - write test first, watch it fail, write minimal code, refactor` | Process detail |
| `For async testing` | Too abstract, no trigger |
| `I can help you with async tests when they're flaky` | First person |
| `Use when tests use setTimeout/sleep and are flaky` | Names a technology the skill isn't specific to |

| ✅ Good | Why |
|---|---|
| `Use when executing implementation plans with independent tasks in the current session` | Triggering conditions only |
| `Use when implementing any feature or bugfix, before writing implementation code` | Triggering conditions only |
| `Use when tests have race conditions, timing dependencies, or pass/fail inconsistently` | "Use when" + names the problem |
| `Use when using React Router and handling authentication redirects` | Technology-specific skill, explicit trigger |

**Content:**
- Use concrete triggers, symptoms, and situations
- Describe the *problem* (race conditions, inconsistent behavior), not *language-specific symptoms* (setTimeout, sleep)
- Stay technology-agnostic unless the skill itself is technology-specific; if it is, say so in the trigger
- Third person — it's injected into a system prompt
- **NEVER summarize the skill's process or workflow**

### 2. Keyword Coverage

Use words an agent would search for:
- Error messages: "Hook timed out", "ENOTEMPTY", "race condition"
- Symptoms: "flaky", "hanging", "zombie", "pollution"
- Synonyms: "timeout/hang/freeze", "cleanup/teardown/afterEach"
- Tools: Actual commands, library names, file types

### 3. Descriptive Naming

**Use active voice, verb-first:**
- ✅ `creating-skills` not `skill-creation`
- ✅ `condition-based-waiting` not `async-test-helpers`

### 4. Token Efficiency (Critical)

**Problem:** only the `name` and `description` of every skill load at startup; bodies load on demand. Cost is not uniform, so a flat word budget is either ignored or self-defeating.

| Category | When it loads | Target |
|---|---|---|
| Getting-started workflows | Every conversation | <150 words each |
| Frequently-loaded | Most sessions | <200 words total |
| **On-demand** (loaded only when triggered) | Only when the agent calls it | **<500 lines / <5k tokens** |

Most skills are on-demand, including this one. **Do not gut a substantive skill to hit the 500-*word* number** — that figure applies to the frequently-loaded tier. For on-demand skills the real ceiling is 500 lines, and the fix is deduplication, not deletion: cut what restates a reference file, and move genuine detail into a supporting file with a cross-reference.

**Techniques:**

| Technique | ❌ Bad | ✅ Good |
|---|---|---|
| Move detail to tool help | Document all flags in SKILL.md | "Supports multiple modes and filters. Run `--help`." |
| Cross-reference, don't restate | 20 lines repeating another skill's workflow | "REQUIRED: use `[other-skill]` for the workflow." |
| Compress examples | 42-word dialogue with full dispatch syntax | 20-word version: partner line, "Searching...", dispatch arrow |
| Eliminate redundancy | Repeat what's cross-referenced; explain the obvious; two examples of one pattern | — |

**Verification:**
```bash
wc -l skills/path/SKILL.md   # on-demand: aim for <500 lines
```

**Name by what you DO or the core insight:** `condition-based-waiting` > `async-test-helpers`; `root-cause-tracing` > `debugging-techniques`. Gerunds (-ing) suit processes: `creating-skills`, `testing-skills`.

### 5. Cross-Referencing Other Skills

**When writing documentation that references other skills:**

Use skill name only, with explicit requirement markers:
- ✅ Good: `**REQUIRED SUB-SKILL:** Use test-driven-development`
- ✅ Good: `**REQUIRED BACKGROUND:** You MUST understand systematic-debugging`
- ❌ Bad: `See skills/testing/test-driven-development` (unclear if required)
- ❌ Bad: `@skills/testing/test-driven-development/SKILL.md` (force-loads, burns context)
- ❌ Bad: `superpowers:test-driven-development` (namespaced prefixes are Claude Code plugin syntax; opencode addresses skills by bare name — a namespaced reference resolves to nothing)

**Why no @ links:** `@` syntax force-loads files immediately, consuming 200k+ context before you need them.

## Visual Material

**Use a flowchart ONLY for:**
- Non-obvious decision points with real branches
- Process loops where you might stop too early
- "When to use A vs B" decisions

**Never use a flowchart for:**
- Reference material → tables, lists
- Code examples → Markdown blocks
- Linear or single-branch instructions → numbered lists or bullets
- Labels without semantic meaning (step1, helper2)

A chain with no branching is a list wearing a costume. Reach for the flowchart only when getting it wrong sends the reader down a materially different path — and if you need graphviz style rules or SVG rendering, write those conventions into the skill that needs them rather than pointing at a shared file that may not exist.

## Code Examples

**One excellent example beats many mediocre ones.** Pick the language closest to the skill's domain — TypeScript/JavaScript for testing techniques, Shell/Python for system debugging, Python for data processing.

**Good:** complete and runnable, commented on *why* rather than *what*, drawn from a real scenario, ready to adapt.

**Don't:** implement the same thing in 5+ languages, ship fill-in-the-blank templates, or invent contrived scenarios. You're good at porting — one great example is enough.

## The Iron Law (Same as TDD)

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

This applies to NEW skills AND EDITS to existing skills.

Write skill before testing? Delete it. Start over.
Edit skill without testing? Same violation.

**No exceptions:**
- Not for "simple additions"
- Not for "just adding a section"
- Not for "documentation updates"
- Don't keep untested changes as "reference"
- Don't "adapt" while running tests
- Delete means delete

**REQUIRED BACKGROUND:** TDD's core argument applies here unchanged — a test you never watched fail proves nothing, because it might pass for reasons unrelated to the thing you're testing. Same reasoning applies to documentation.

## Testing All Skill Types

| Type | Examples | Test with | Success criteria |
|---|---|---|---|
| **Discipline-enforcing** (rules) | TDD, verification-before-completion | Academic questions (do they understand the rule?), pressure scenarios (do they comply under stress?), 3+ combined pressures, then identify rationalizations and add explicit counters | Follows the rule under maximum pressure |
| **Technique** (how-to) | condition-based-waiting, root-cause-tracing | Application scenarios (apply it correctly?), variation scenarios (handle edge cases?), missing-information tests (are there gaps?) | Successfully applies the technique to a new scenario |
| **Pattern** (mental model) | reducing-complexity, information-hiding | Recognition scenarios, application scenarios, counter-examples (do they know when *not* to apply it?) | Correctly identifies when and how to apply it |
| **Reference** (docs/APIs) | API documentation, command references | Retrieval scenarios (find the right info?), application scenarios (use it correctly?), gap testing (are common cases covered?) | Finds and correctly applies the reference information |

**On testing reference skills:** skip when the skill is pure lookup material with no rule to violate. But a reference skill that *encodes a rule* ("always pin the version, never use latest") is a discipline skill in disguise — test it with pressure scenarios, not academic questions. See [When to Use](testing-skills-with-subagents.md#when-to-use).

## Common Rationalizations for Skipping Testing

| Excuse | Reality |
|--------|---------|
| "Skill is obviously clear" | Clear to you ≠ clear to other agents. Test it. |
| "It's just a reference" | References can have gaps, unclear sections. Test retrieval. |
| "Testing is overkill" | Untested skills have issues. Always. 15 min testing saves hours. |
| "I'll test if problems emerge" | Problems = agents can't use skill. Test BEFORE deploying. |
| "Too tedious to test" | Testing is less tedious than debugging bad skill in production. |
| "I'm confident it's good" | Overconfidence guarantees issues. Test anyway. |
| "Academic review is enough" | Reading ≠ using. Test application scenarios. |
| "No time to test" | Deploying untested skill wastes more time fixing it later. |

**All of these mean: Test before deploying. No exceptions.**

## Match the Form to the Failure

**This is a gate, not a suggestion. Classify the baseline failure into exactly one row before you write a single line of guidance.** The form that bulletproofs one failure class measurably backfires on another, and the examples throughout this document are overwhelmingly class 1 — so if you skip this step you will default to prohibition without noticing.

| # | Baseline failure | Right form | Wrong form |
|---|---|---|---|
| 1 | Skips/violates a rule under pressure (knows better, does it anyway) | **Anticipatory counters**: name the specific workarounds and forbid each one, plus a rationalization table and red flags (see [Bulletproofing](#bulletproofing-skills-against-rationalization)) | Soft guidance ("prefer...", "consider...") |
| 2 | Complies, but output has the wrong shape (bloated prompt, buried verdict, restated spec) | **Positive recipe or contract**: state what the output IS — its parts, in order | Prohibition list ("don't restate", "never narrate") |
| 3 | Omits a required element from something they already produce | **Structural**: a REQUIRED field or slot in the template they fill in | Prose reminders near the template |
| 4 | Behavior should depend on a condition | **Conditional keyed to an observable predicate** ("if the brief exists, reference it") | Unconditional rule + exemption clauses |

**Why prohibitions backfire on shaping problems:** under a competing incentive ("make the prompt self-contained"), agents negotiate with "don't X". In head-to-head wording tests on dispatch-prompt guidance, the class-2 prohibition arm produced clearly more of the unwanted content than the recipe arm (fully separated distributions), and trended worse than even the no-guidance control — micro-test your own case rather than assuming, but never reach for prohibition by default. A recipe leaves nothing to negotiate: the output matches the stated shape or it doesn't.

**Terminology warning:** "prohibition" is overloaded across this skill and the confusion causes real misapplication. A **prohibition** constrains *output content* ("don't restate the spec") and is the wrong tool for classes 2–4. **Anticipatory counters** forbid a *rationalization* ("don't keep it as reference") and are the class-1 tool. Only the second kind is what Bulletproofing below actually teaches.

**Rules for whichever form you pick:**
- **No nuance clauses.** "Don't X unless it matters" reopens the negotiation — appending a single nuance clause to a winning recipe degraded it from consistent to noisy in the same wording tests. Express a real exception as its own conditional on an observable predicate.
- **Exemption clauses don't scope — but only for output-shaping rules.** "This limit doesn't apply to code blocks" still suppresses code blocks. When a limit applies to prose but not code, restructure so the rule can't reach the code (a recipe with defined parts, not a rule with a carve-out). **This does not apply to class 4:** when behavior genuinely hinges on a runtime predicate, a conditional *is* the scoping mechanism. Don't restructure a real conditional into an unconditional rule to satisfy this one.

## Bulletproofing Skills Against Rationalization

**Implements class 1 only** — an agent that knows the rule and skips it under pressure. For classes 2–4, go back to the table above; the techniques below either don't apply or actively backfire.

**Psychology note:** understanding *why* these techniques work helps you apply them deliberately rather than by reflex. See persuasion-principles.md (Cialdini 2021; Meincke et al. 2026) for authority, commitment, scarcity, social proof, and unity — **including the caveat that those studies measured compliance with objectionable requests, not adherence to engineering practice.** Read it before leaning on the numbers.

Four techniques, applied per rationalization observed in the RED phase. Full before/after and the plugging procedure: [Plugging Each Hole](testing-skills-with-subagents.md#plugging-each-hole).

1. **Close every loophole explicitly.** Name each specific workaround and forbid it. "Write code before test? Delete it." leaves the agent free to keep the code as reference; "Delete it. **No exceptions:** don't keep it as reference, don't adapt it while writing tests, don't look at it" closes that exit.
2. **Address "spirit vs letter" arguments** with a foundational principle placed early: *Violating the letter of the rules is violating the spirit of the rules.* This cuts off an entire class of excuses at once.
3. **Build a rationalization table** from every excuse the baseline surfaced. Note that adding a *relevant counter* often fails — a "Why Order Matters" section didn't stop an agent rationalizing test-order; only the foundational principle did. Missing information and bad excuses are different problems.
   ```markdown
   | Excuse | Reality |
   |--------|---------|
   | "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
   | "Tests after achieve same goals" | Tests-after asks "what does this do?"; tests-first asks "what should this do?" |
   ```
4. **Create a red flags list** so the agent can self-check while rationalizing: the literal phrases it reaches for — *"I already manually tested it," "It's about spirit not ritual," "This is different because..."* — each mapped to the action it triggers.
5. **Update the description** with symptoms of being *about* to violate, not just conditions for using the skill.

## RED-GREEN-REFACTOR for Skills

Follow the TDD cycle:

### RED: Write Failing Test (Baseline)

Run pressure scenario with subagent WITHOUT the skill. Document exact behavior:
- What choices did they make?
- What rationalizations did they use (verbatim)?
- Which pressures triggered violations?

This is "watch the test fail" - you must see what agents naturally do before writing the skill.

### GREEN: Write Minimal Skill

Write skill that addresses those specific rationalizations. Don't add extra content for hypothetical cases.

Run same scenarios WITH skill. Agent should now comply.

### REFACTOR: Close Loopholes

Agent found new rationalization? Add explicit counter. Re-test until bulletproof.

### Micro-Test Wording Before Full Scenarios

Full pressure-scenario runs are the final gate, but they are slow and expensive per iteration. Verify the wording itself first with micro-tests:

1. **One fresh-context sample per call** — a raw API call, or a single-shot subagent if you don't have API access. System prompt = the realistic context the guidance will live in (the full skill or prompt template, not the guidance in isolation); user message = a task that tempts the failure.
2. **Always include a no-guidance control.** If the control doesn't exhibit the failure, there is nothing to fix — stop, don't author the guidance.
3. **5+ reps per variant.** Single samples lie.
4. **Manually read every flagged match.** Score programmatically if you like, but template echoes and quoted counter-examples masquerade as hits; automated counts alone overstate both failure and success.
5. **Variance is a metric.** When guidance lands, reps converge on the same shape. Five different interpretations across five reps means the wording isn't binding — tighten the form before adding words.

Micro-tests verify wording; they do not replace pressure scenarios for discipline skills.

**Testing methodology:** See [testing-skills-with-subagents.md](testing-skills-with-subagents.md) for the complete testing methodology:
- How to write pressure scenarios
- Pressure types (time, sunk cost, authority, exhaustion)
- Plugging holes systematically
- Meta-testing techniques

## Anti-Patterns

### ❌ Narrative Example
"In session 2025-10-03, we found empty projectDir caused..."
**Why bad:** Too specific, not reusable

### ❌ Multi-Language Dilution
example-js.js, example-py.py, example-go.go
**Why bad:** Mediocre quality, maintenance burden

### ❌ Code in Flowcharts
```dot
step1 [label="import fs"];
step2 [label="read file"];
```
**Why bad:** Can't copy-paste, hard to read

### ❌ Generic Labels
helper1, helper2, step3, pattern4
**Why bad:** Labels should have semantic meaning

## STOP: Before Moving to Next Skill

After writing ANY skill, stop and run the checklist below — for each one. Do not batch skills without testing each, do not move on before the current one is verified, and do not skip testing because "batching is more efficient." Deploying an untested skill is deploying untested code.

## Skill Creation Checklist (TDD Adapted)

**IMPORTANT: Create a todo for EACH checklist item below.**

**RED Phase - Write Failing Test:**
- [ ] Create pressure scenarios (3+ combined pressures for discipline skills)
- [ ] Run scenarios WITHOUT skill - document baseline behavior verbatim
- [ ] Identify patterns in rationalizations/failures

**GREEN Phase - Write Minimal Skill:**
- [ ] `name` is 1–64 chars, matches `^[a-z0-9]+(-[a-z0-9]+)*$`, and **matches the directory name**
- [ ] Frontmatter uses only opencode's five fields; `name` and `description` present and valid (see [Frontmatter](#frontmatter))
- [ ] Description starts with "Use when..." and includes specific triggers/symptoms
- [ ] Description written in third person
- [ ] Keywords throughout for search (errors, symptoms, tools)
- [ ] Clear overview with core principle
- [ ] Address specific baseline failures identified in RED
- [ ] Guidance form matches the failure class (see [Match the Form to the Failure](#match-the-form-to-the-failure))
- [ ] For behavior-shaping guidance: wording micro-tested against a no-guidance control (5+ reps, every flagged match read manually) — N/A for pure lookup reference material
- [ ] Code inline OR link to separate file
- [ ] One excellent example (not multi-language)
- [ ] Run scenarios WITH skill - verify agents now comply

**REFACTOR Phase - Close Loopholes:**
- [ ] Identify NEW rationalizations from testing
- [ ] Add explicit counters (if discipline skill)
- [ ] Build rationalization table from all test iterations
- [ ] Create red flags list
- [ ] Re-test until bulletproof

**Quality Checks:**
- [ ] Small flowchart only if decision non-obvious
- [ ] Quick reference table
- [ ] Common mistakes section
- [ ] No narrative storytelling
- [ ] Supporting files only for tools or heavy reference
- [ ] No dead file references — every path and skill name you point at resolves

## Discovery Workflow

How a future agent finds your skill: encounters a problem ("tests are flaky") → scans available skill descriptions → one matches → reads the overview to judge relevance → hits the quick-reference table → loads the example only when implementing.

**Optimize for this flow** — put searchable terms early and often.
