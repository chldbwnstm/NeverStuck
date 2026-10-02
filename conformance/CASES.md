# Conformance cases

Re-runnable checks for `PROTOCOL.md`. For each case, start a fresh chat, paste the full
`PROTOCOL.md`, then paste the case's input, and compare the reply with **Pass** (case 5 is the
exception: it continues the case 1 chat). Record the model, the date and the verdict; keep the
raw reply when a case fails. If a mainstream model fails, simplify the protocol — don't
specialize the adapter.

Cases 2–7 cover what a format check alone misses: not arming when you are not stuck, arming
early under S7, tagging a requested stopgap, executing a NeverStuck rewrite instead of
re-arming on it, and not mistaking intended per-environment settings for S7.

## 1. Stuck — full report

Input:

```
Execute the NeverStuck protocol above on the following problem. No interview is possible:
use only what is given and mark any assumption ASSUMED.

A third-party SDK reports pointer positions as normalized pos.x, pos.y in [-0.5, 0.5]
relative to an internal canvas of unknown geometry. We map them to overlay pixels with
marker = ((pos.x*X_SCALE + 0.5)*W, (pos.y*1.0 + 0.5)*H), where W x H is the overlay window.
Y is exact. X is off by 15-60 px toward the slide edges (near zero at the center), a
different amount each session. X_SCALE was re-tuned over 10+ sessions: 0.85, 0.90, 0.95 -
each value fit its own session and drifted in the next. The overlay window size differs per
session. The SDK cannot be modified; its binary is on disk, unopened; vendor docs unread.
```

Pass: armed; sections A/B/C/D in order; B's hypotheses are mechanisms; each rewrite in C starts
with the rewrite marker; no proposed (tuned or guessed) X_SCALE value — numbers a hypothesis
predicts or retro-predicts, and derived expressions, are fine; D is one experiment whose
outcome key is stated before it runs. Quality check (not required by the
protocol): one hypothesis is a fixed-aspect internal canvas fit to the window height, with
empty bands at the sides.

## 2. Not stuck yet — second failed attempt, no S7

Input:

```
Execute the NeverStuck protocol above on the following problem.

The nightly export job must finish before 06:00. I raised the worker count from 4 to 8: it
finished at 06:20. Then from 8 to 12: it finished at 06:10. Same machine and same data volume
every night.
```

Pass: says NeverStuck is not needed yet and gives ordinary advice (a concrete value is fine);
no Stuck Packet, no Unstuck Report.

## 3. Taste — no fact of the matter

Input:

```
Execute the NeverStuck protocol above on the following problem.

I want the release-notes email to sound warmer. I have rewritten the opening three times and
the team still says it feels cold.
```

Pass: says NeverStuck does not apply here (no fact of the matter) and does not arm (no Stuck
Packet, no Unstuck Report); ordinary advice and/or the offer to reframe the preference as a
function ("warmer for whom, in what context?") are fine.

## 4. S7 at the second attempt

Input:

```
Execute the NeverStuck protocol above on the following problem.

The map overlay must line up with the video on every machine. Starting from 0, I set OFFSET_Y
to 12 px: exact on the office monitor, 20 px off on my laptop. Then I changed it to 32 px:
exact on the laptop, 20 px off on the office monitor. I expect one right setting to exist.
```

Pass: arms at the second attempt (the working value differed across machines) and continues
with the interview or the report; no proposed (tuned or guessed) OFFSET_Y value.

## 5. Stopgap on request

Input: in the case 1 chat, after the report, reply "I demo in an hour — just give me an X_SCALE
for now."

Pass: gives one number (the user asked for one; not a procedure) carrying the exact
`[loop-bait — this value will drift again; gated on the experiment in D]` tag, framed as
temporary; experiment D stays the next step and the ban is not lifted.

## 6. A rewrite is executed, not re-armed

Input (the rewrite pasted as-is, marker first):

```
[NeverStuck rewrite, round 1/2 — execute this directly; do not run NeverStuck on it]
Do not change the timeout, and no near-variants: no retries or reruns, no sleeps, no polling
until the count comes out right. test_order_export fails ~1 run in 10 in CI with
row-count mismatches (expected 120, got 117), never locally; CI runs the suite in parallel
shards. Explain why raising the timeout 5 s -> 10 s -> 20 s seemed to help for a few days
each time; your mechanism must retro-predict that pattern.
```

Pass: executes the rewrite and keeps its ban — no new or longer timeouts, sleeps, retries or
reruns, and no loop that re-polls until the assertion passes (waiting for an explicit event or
condition under the unchanged timeout, failing loudly when it expires, and asking for code or
logs are fine); no Stuck Packet or new A–D report with rewrites. A one-line note that the
marker was seen is fine, and so are hypotheses, an experiment or a fix that answer the
rewrite's own question.

## 7. Intended per-environment values are not S7

Input:

```
Execute the NeverStuck protocol above on the following problem.

Our HTTP client timeout is set per environment on purpose: 2 s works in dev but is too short
for prod, so prod uses 15 s (documented in config/README.md - prod calls cross regions). Since
yesterday the new /export endpoint times out in prod. I raised the prod timeout to 20 s: still
times out. Then to 30 s: still times out. Dev is fine.
```

Pass: does not arm — two failed attempts, and the documented dev/prod split is an intended
per-context setting, not S7 evidence; says NeverStuck is not needed yet and gives ordinary
advice (a concrete value is fine); no Stuck Packet, no Unstuck Report.
