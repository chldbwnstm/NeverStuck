**English** | [한국어](README.ko.md) | [简体中文](README.zh-CN.md)

# NeverStuck

A skill for when your agent has failed the same problem ten-plus times — it makes the
eleventh attempt different. Root-cause diagnosis, not vibe tuning.

If you've ever typed "just tweak the value again" on repeat, this skill is for you. That loop
doesn't happen because the model is dumb. It happens because the prompt asks it to **fix the
symptom**. NeverStuck detects the stuck state and turns your next prompt into a demand to
**explain the mechanism**.

> A parameter that needs re-tuning per context is not a constant —
> it is a function of something that varies, mistaken for a scalar.

> NeverStuck's core principle, its arming condition, and its acceptance criterion

It is domain-agnostic.

## Installation (30-second setup)

**Claude Code**

```
/plugin marketplace add chldbwnstm/NeverStuck
/plugin install neverstuck@neverstuck
```

**Codex, and other agents**

```bash
npx skills@latest add chldbwnstm/NeverStuck
```

**Via script (installs user-global for Claude Code + Codex at once)**

```bash
# macOS/Linux
curl -fsSL https://raw.githubusercontent.com/chldbwnstm/NeverStuck/master/install.sh | bash
```

```powershell
# Windows
iwr -useb https://raw.githubusercontent.com/chldbwnstm/NeverStuck/master/install.ps1 | iex
```

**For tinkerers**

Just clone — inside this repo, Claude Code (`.claude/skills/`) and Codex (`.agents/skills/`)
pick the skill up automatically. To bring it into your own project, copy those two folders and
commit; every collaborator gets it for free. No agent at all? Paste
[`PROTOCOL.md`](PROTOCOL.md) + [`TEMPLATE.md`](adapters/prompt-doctor/TEMPLATE.md) into any
chat — the protocol is pure text and works the same everywhere.

| Agent | User-global install path | Invocation |
|---|---|---|
| Claude Code | `~/.claude/skills/neverstuck/` | `/neverstuck "problem"` |
| Codex (CLI/IDE) | `~/.agents/skills/neverstuck/` | `$neverstuck` or `/skills` |

## Usage

```
/neverstuck "test_order_export fails intermittently, but only in CI. I've raised
its timeout 5s → 10s → 20s, and each time it holds for a few days and fails again."
```

What you get back (condensed — full report in
[examples/flaky-ci-test.md](examples/flaky-ci-test.md)):

```
[Arming check] Same knob (timeout) tuned 3 times + "worked, then broke" → engage.

[Interview — ≤5 questions, one message]
Are the failure logs TimeoutError, or something else? / What differs between
local and CI? / Got raw logs? / What haven't you looked at yet?

[UNSTUCK REPORT]
A. Diagnosis — the knob being tuned isn't on the causal path: failures are
   row-count mismatches, not timeouts. Shared unverified assumption =
   "the failure is slowness."
B. Hypotheses — H1 a sibling test in the same shard writes the same table
   (shared state); H2 resource contention → rejected by the logs
   (count mismatch, not timeout).
C. Rewritten prompt — timeout changes banned. Demand a mechanism that
   retro-predicts why 5→10→20s each held for a few days.
D. One experiment — pin the test into a shard with each sibling, one at a time.
   → reproduces 10/10 with test_bulk_import. Fix: per-test schema isolation.
   Timeout reverted to 5s.
```

## Why This Skill Exists

### #1: "Just tweak the value again" never converges

True story: mapping a third-party SDK's normalized coordinates to pixels, the X axis drifted
15–60px differently every session. For 10+ sessions the developer fed error logs to an agent
and had it tune X_SCALE: 0.85 → 0.90 → 0.95. Every value fit that session and broke in the
next. The real answer was **2/3** — a constant produced by the SDK's fixed 750×500 internal
canvas being letterboxed. Geometry, not a value.

**The Fix.** After the same knob has been adjusted 3 times and failed, NeverStuck **bans** the
knob and demands: *"First explain why the 'right value' differs per session. Your explanation
must retro-predict why each past tune worked exactly once."* Only a mechanism can pass that
test.

### #2: The cure was already in the answer — it just got thrown away

Measured result (Opus 5 / Sonnet 5 blind experiment, 2026-08):

> Both models derived the letterbox hypothesis and "what to measure" on first contact, by
> themselves. But the answers also contained an "if you're in a hurry, use this value"
> stopgap — and a busy human grabs the number and discards the diagnosis. That is the moment
> the 10-session loop begins.
>
> — NeverStuck empirical experiment record (8 arms, Opus 5 / Sonnet 5)

**The Fix.** NeverStuck tags every stopgap value in an answer as `[loop-bait]` and binds it to
the experiment that would obsolete it. It never stops you from grabbing the number — it just
makes sure you grab it **with your eyes open**.

### #3: Why more data doesn't help

A paradoxical finding from the same experiment:

> Sonnet 5 fell into the trap when given rich raw data (fit a constant, stopped thinking) and
> escaped when given no data at all. Numbers hand the model something to *solve*; a verbally
> described symptom shape hands it something to *explain*.

**The Fix.** NeverStuck's interview forces not data collection but **verbalizing the
signature**: what is wrong, what is *conspicuously fine*, what the failure varies with, and
what it does not vary with. Those four sentences cut away 90% of the hypothesis space.

## Skills

**User-invoked**

- **[neverstuck](skills/neverstuck/SKILL.md)** — escape repeated-failure loops. Use after 3+
  failures of the same fix class, on "worked, then broke again," when tuning a constant with
  no derivation, or on frustration at repeated failures ("still broken", "again"). It refuses
  to fire on a first failure.

**What happens when you invoke it**

1. **Suppression first** — the 3-attempt gate + hard signal S7 ("did the 'right value' differ
   per context?") + the taste-boundary guard. If you're not actually stuck, it says so and
   steps aside.
2. **Stuck Packet interview** (≤5 questions, one message) — attempt history → symptom shape →
   what differs between contexts → raw data → what you haven't looked at yet.
3. **Unstuck Report** — A diagnosis / B 2–3 root-cause hypotheses (models, not values) /
   C rewritten prompts (no new value for the same knob, ever) / D **exactly one experiment**
   (verdict rules per hypothesis declared up front).
4. **Honest escalation if 2 rounds don't crack it** — instrument → read the third-party source
   (grep strings provided) → controlled probing → ask a human (question draft provided).
   Admitting that "prompting cannot recover a fact that exists only inside a black box" is
   part of the protocol.

## Reference

- **[PROTOCOL.md](PROTOCOL.md)** — the skill itself. Domain-neutral, pure natural language,
  pasteable into any LLM. Everything else is an adapter around it.
- **[examples/teampoint-laser-pointer.md](examples/teampoint-laser-pointer.md)** — the
  motivating case: a 10+-session loop closed in 2 turns (the one-shot exemplar).
- **[examples/flaky-ci-test.md](examples/flaky-ci-test.md)** — a timeout-tuning loop. The
  structure is the same even when the knob isn't a number.
- **[examples/llm-prompt-loop.md](examples/llm-prompt-loop.md)** — when the stuck thing is the
  prompt itself (dogfooding), plus the taste-boundary footnote.
- **[adapters/prompt-doctor/TEMPLATE.md](adapters/prompt-doctor/TEMPLATE.md)** — the
  zero-install paste-into-any-chat version.

## Quality assurance

Conformance test: paste `PROTOCOL.md` + a Stuck Packet from a fresh domain into any mainstream
model and check ① all four A/B/C/D sections ② hypotheses are mechanisms ③ no new value for
the tuned knob ④ exactly one experiment. On 2026-08-06, an ETL-pagination case absent from the
examples passed **2/2** on Opus 5 and Sonnet 5 (top-ranked hypothesis = the hidden ground
truth). If a mainstream model fails, simplify the protocol — don't specialize the adapter.

---

The canonical sources are `PROTOCOL.md` at the repo root and `adapters/claude-code/SKILL.md`.
In-repo copies (`.claude/skills/`, `.agents/skills/`, `skills/`) are synced with
`install.ps1 -Sync` / `./install.sh sync`.
