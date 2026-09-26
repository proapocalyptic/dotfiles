# Persuasion Principles for Skill Design

## Overview

LLMs respond to the same persuasion principles as humans. Understanding this psychology helps you design more effective skills - not to manipulate, but to ensure critical practices are followed even under pressure.

**Research foundation:** Meincke et al. (2026) tested 7 persuasion principles across N=126,000 conversations with three models. Persuasion raised compliance from 35.3% to 51.3% — a 16-point lift. Reasoning models resisted persuasion more than earlier models, though not completely.

**Scope caveat — read before citing the numbers:** These studies measured compliance with *objectionable requests* (insult the user; synthesize a regulated drug), not adherence to legitimate engineering practice. Transferring the effect to "follow TDD" or "run the tests" is an extrapolation, not a measured finding. Treat the research as evidence that LLMs are *susceptible* to social influence — not as a quantified effect size for documentation discipline. A skill that cites a jailbreak study to justify compliance theater is misrepresenting it.

## The Seven Principles

### 1. Authority
**What it is:** Deference to expertise, credentials, or official sources.

**How it works in skills:**
- Imperative language: "YOU MUST", "Never", "Always"
- Non-negotiable framing: "No exceptions"
- Eliminates decision fatigue and rationalization

**When to use:**
- Discipline-enforcing skills (TDD, verification requirements)
- Safety-critical practices
- Established best practices

**Example:**
```markdown
✅ Write code before test? Delete it. Start over. No exceptions.
❌ Consider writing tests first when feasible.
```

### 2. Commitment
**What it is:** Consistency with prior actions, statements, or public declarations.

**How it works in skills:**
- Require announcements: "Announce skill usage"
- Force explicit choices: "Choose A, B, or C"
- Use tracking: todos for checklists

**When to use:**
- Ensuring skills are actually followed
- Multi-step processes
- Accountability mechanisms

**Example:**
```markdown
✅ When you find a skill, you MUST announce: "I'm using [Skill Name]"
❌ Consider letting your partner know which skill you're using.
```

### 3. Scarcity
**What it is:** Urgency from time limits or limited availability.

**How it works in skills:**
- Time-bound requirements: "Before proceeding"
- Sequential dependencies: "Immediately after X"
- Prevents procrastination

**When to use:**
- Immediate verification requirements
- Time-sensitive workflows
- Preventing "I'll do it later"

**Example:**
```markdown
✅ After completing a task, IMMEDIATELY request code review before proceeding.
❌ You can review code when convenient.
```

### 4. Social Proof
**What it is:** Conformity to what others do or what's considered normal.

**How it works in skills:**
- Universal patterns: "Every time", "Always"
- Failure modes: "X without Y = failure"
- Establishes norms

**When to use:**
- Documenting universal practices
- Warning about common failures
- Reinforcing standards

**Example:**
```markdown
✅ Checklists without todo tracking = steps get skipped. Every time.
❌ Some people find a todo list helpful for checklists.
```

### 5. Unity
**What it is:** Shared identity, "we-ness", in-group belonging.

**How it works in skills:**
- Collaborative language: "our codebase", "we're colleagues"
- Shared goals: "we both want quality"

**When to use:**
- Collaborative workflows
- Establishing team culture
- Non-hierarchical practices

**Example:**
```markdown
✅ We're colleagues working together. I need your honest technical judgment.
❌ You should probably tell me if I'm wrong.
```

### 6. Reciprocity
**What it is:** Obligation to return benefits received.

**How it works:**
- Use sparingly - can feel manipulative
- Rarely needed in skills

**When to avoid:**
- Almost always (other principles more effective)

### 7. Liking
**What it is:** Preference for cooperating with those we like.

**How it works:**
- **DON'T USE for compliance**
- Conflicts with honest feedback culture
- Creates sycophancy

**When to avoid:**
- Always for discipline enforcement

## Principle Combinations by Skill Type

**These pairings are extrapolated, not measured.** Both studies varied one principle at a time against a matched control; no combination was ever tested. Treat the left column as a starting hypothesis to validate against your own baseline, not a finding.

| Skill Type | Try | Avoid |
|------------|-----|-------|
| Discipline-enforcing | Authority + Commitment + Social Proof | Liking, Reciprocity |
| Guidance/technique | Moderate Authority + Unity | Heavy authority |
| Collaborative | Unity + Commitment | Authority, Liking |
| Reference | Clarity only | All persuasion |

## Why This Works: The Psychology

**Bright-line rules reduce rationalization:**
- "YOU MUST" removes decision fatigue
- Absolute language eliminates "is this an exception?" questions
- Explicit anti-rationalization counters close specific loopholes

**Implementation intentions create automatic behavior:**
- Clear triggers + required actions = automatic execution
- "When X, do Y" more effective than "generally do Y"
- Reduces cognitive load on compliance

**LLMs are parahuman:**
- Trained on human text containing these patterns
- Authority language precedes compliance in training data
- Commitment sequences (statement → action) frequently modeled
- Social proof patterns (everyone does X) establish norms

## Ethical Use

**Legitimate:**
- Ensuring critical practices are followed
- Creating effective documentation
- Preventing predictable failures

**Illegitimate:**
- Manipulating for personal gain
- Creating false urgency
- Guilt-based compliance

**The test:** Would this technique serve the user's genuine interests if they fully understood it?

## Research Citations

**Cialdini, R. B. (2021).** *Influence: The Psychology of Persuasion (New and Expanded).* Harper Business.
- Seven principles of persuasion
- Empirical foundation for influence research

**Meincke, L., Shapiro, D., Duckworth, A. L., Mollick, E., Mollick, L., Van den Bulte, C., & Cialdini, R. (2026).** Persuading Large Language Models to Comply with Objectionable Requests. *PNAS*, 123(21), e2535868123. https://doi.org/10.1073/pnas.2535868123
- Primary result: 7 principles, N=126,000 conversations, 3 models (GPT-5 mini, Claude Haiku 4.5, Gemini 3 Flash), 6 substances
- Compliance 35.3% → 51.3% (16 percentage points)
- Reasoning models more resistant than earlier models, still susceptible
- **Preliminary study (superseded):** Meincke et al. (2025). *Call Me A Jerk: Persuading AI to Comply with Objectionable Requests.* SSRN 5357179. N=28,000, GPT-4o-mini only, 33.3% → 72.0% (p < .001). The "doubling" figure comes from this smaller, single-model preprint — cite it only with that scope attached.
- Both: validates the parahuman model of LLM behavior

## Quick Reference

When designing a skill, ask:

1. **What type is it?** (Discipline vs. guidance vs. reference)
2. **What behavior am I trying to change?** — and which failure class is it? (See Match the Form to the Failure in SKILL.md.)
3. **Which principle(s) apply?** (Usually authority + commitment for discipline — a hypothesis, not a result)
4. **Am I combining too many?** (Don't use all seven)
5. **Did my baseline test actually show this failure?** If not, no principle is warranted — the no-guidance control is the arbiter.
6. **Is this ethical?** (Serves user's genuine interests?)
