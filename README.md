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

Invoke it with `/neverstuck` (it is also listed as `/neverstuck:neverstuck`). To update:
`/plugin marketplace update neverstuck`, then **Update now** on the plugin in `/plugin`
(auto-update is off by default for third-party marketplaces). From a shell:
`claude plugin marketplace update neverstuck`, then `claude plugin update neverstuck@neverstuck`.

**Codex, and other agents**

```bash
npx skills@latest add chldbwnstm/NeverStuck
```

To update, run the same command again — `npx skills update` may skip this skill, because the
repo ships it in several folders.

**Via script (installs user-global for Claude Code + Codex at once)**

```bash
# macOS/Linux
curl -fsSL https://raw.githubusercontent.com/chldbwnstm/NeverStuck/master/install.sh | bash
# one agent only: ... | bash -s -- claude   (or codex)
```

```powershell
# Windows
iwr -useb https://raw.githubusercontent.com/chldbwnstm/NeverStuck/master/install.ps1 | iex
# one agent only:
& ([scriptblock]::Create((iwr -useb https://raw.githubusercontent.com/chldbwnstm/NeverStuck/master/install.ps1).Content)) -Target codex
```

Re-run the same line to update. Pick one channel per agent — plugin, npx, script, or copy:
installing twice leaves two copies that drift apart.

**For tinkerers**

Just clone — inside this repo, Claude Code (`.claude/skills/`) and Codex (`.agents/skills/`)
pick the skill up automatically. To bring it into your own project, copy those two folders and
commit; every collaborator gets it for free. No agent at all? Paste
[`PROTOCOL.md`](PROTOCOL.md) + [`TEMPLATE.md`](adapters/prompt-doctor/TEMPLATE.md) into any
chat — the protocol is pure text and works the same everywhere.

| Agent | User-global install path | Invocation |
|---|---|---|
| Claude Code | `~/.claude/skills/neverstuck/` (or `$CLAUDE_CONFIG_DIR/skills/neverstuck/`) | `/neverstuck "problem"` |
| Codex (CLI/IDE) | `~/.agents/skills/neverstuck/` | `$neverstuck` or `/skills` |

A complete install is one folder holding `SKILL.md`, `PROTOCOL.md` and
`examples/teampoint-laser-pointer.md`; every channel above ships all three. If you copy files
by hand, bring all three — `SKILL.md` alone is only a pointer to `PROTOCOL.md`.

## Usage

```
/neverstuck "test_order_export fails intermittently, but only in CI. I've raised its
timeout three times (to 5s, 10s, then 20s), and each time it holds for a few days and
fails again."
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
   (count mismatch, not timeout); H3 a true race → weakened (never fails alone).
C. Rewritten prompt — timeout changes banned. Demand a mechanism that
   retro-predicts why 5→10→20s each held for a few days.
D. One experiment — pin the test into a shard with each sibling, one at a time.
   Reproduces with one sibling only ⇒ H1; with none ⇒ revisit H3.
```

After you run D: it reproduces 10/10 with `test_bulk_import` → per-test schema isolation; the
timeout goes back to 5 s.

## Why This Skill Exists

### #1: "Just tweak the value again" never converges

True story: mapping a third-party SDK's normalized coordinates to pixels, the X axis drifted
15–60px differently every session. For 10+ sessions the developer fed error logs to an agent
and had it tune X_SCALE: 0.85 → 0.90 → 0.95. Every value fit that session and broke in the
next. The real answer was **2/3** = 500/750 — not a better guess but a constant *derived* from
the SDK's fixed 750×500 internal canvas, which no amount of tuning around 0.9 could land on.
Geometry, not a value. ([The worked example](examples/teampoint-laser-pointer.md) reconstructs
the case with an idealized model.)

**The Fix.** After the same knob has been adjusted 3 times and failed, NeverStuck **bans** the
knob and demands: *"First explain why the 'right value' differs per session. Your explanation
must retro-predict why each past tune worked exactly once."* Only a mechanism can pass that
test.

### #2: The cure was already in the answer — it just got thrown away

From a small blind experiment (Opus 5 / Sonnet 5, 2026-08; one run per arm, synthetic data):

> Both models derived the letterbox hypothesis and "what to measure" on first contact, by
> themselves. But the answers also contained an "if you're in a hurry, use this value"
> stopgap — and a busy human grabs the number and discards the diagnosis. That is the moment
> the 10-session loop begins.
>
> — NeverStuck experiment notes (8 arms, one run each, Opus 5 / Sonnet 5)

**The Fix.** NeverStuck tags every stopgap value in an answer as `[loop-bait]` and binds it to
the experiment that would obsolete it. It never stops you from grabbing the number — it just
makes sure you grab it **with your eyes open**.

### #3: Why more data doesn't help

A paradoxical observation from the same experiment (one run per arm — a hint, not a law):

> Sonnet 5 fell into the trap when given rich raw data (fit a constant, stopped thinking) and
> escaped when given no data at all. Numbers hand the model something to *solve*; a verbally
> described symptom shape hands it something to *explain*.

**The Fix.** NeverStuck's interview forces not data collection but **verbalizing the
signature**: what is wrong, what is *conspicuously fine*, what the failure varies with, and
what it does not vary with. Those four sentences rule out most of the hypothesis space.

## Skills

**User- or model-invoked**

- **[neverstuck](skills/neverstuck/SKILL.md)** — escape repeated-failure loops. Use after 3+
  failures of the same fix class, on "worked, then broke again," when tuning a constant with
  no derivation, or on frustration at repeated failures ("still broken", "again"). It refuses
  to fire on a first failure.

**What happens when you invoke it**

1. **Suppression first** — the 3-attempt gate + hard signal S7 ("did the 'right value' differ
   per context?" — intended per-environment settings such as dev/prod don't count) + the
   taste-boundary guard. If you're not actually stuck, it says so and steps aside.
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
  motivating case: a real 10+-session loop, reconstructed as a 2-turn protocol run (the
  one-shot exemplar).
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
examples passed **2/2** — one run each on Opus 5 and Sonnet 5 (top-ranked hypothesis = the
hidden ground truth); that packet is not in the repo. Re-runnable cases live in
[`conformance/CASES.md`](conformance/CASES.md), including the ones that must *not* produce a
report (not stuck yet, taste) and the stopgap tag. If a mainstream model fails, simplify the
protocol — don't specialize the adapter.

---

The canonical sources are `PROTOCOL.md` at the repo root, `adapters/claude-code/SKILL.md` and
`examples/teampoint-laser-pointer.md`. In-repo copies (`.claude/skills/`, `.agents/skills/`,
`skills/`) are synced with `install.ps1 -Sync` / `./install.sh sync`, and CI fails if they
drift. When the skill changes, bump `version` in `.claude-plugin/plugin.json` — plugin users
only receive a new version. A user-global install (`~/.claude/skills/`) shadows the in-repo
copy, so before testing `/neverstuck` locally, run `./install.sh` (or `.\install.ps1`) from your
checkout — the one-liners install GitHub `master` — or remove `~/.claude/skills/neverstuck` and
run `./install.sh sync` (or `.\install.ps1 -Sync`).

Licensed under [MIT](LICENSE).
