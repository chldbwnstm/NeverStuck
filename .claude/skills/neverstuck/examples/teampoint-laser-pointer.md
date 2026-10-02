# Worked Example — TeamPoint Laser Pointer (the motivating case)

Based on a real incident: 10+ failed tuning sessions, which in reality ended when a colleague
opened up the SDK, found its fixed 750×500 canvas, and derived the constant 2/3. The packet and
report below reconstruct the case with an idealized model and numbers — one in which the
per-session drift is exact geometry — to show how the protocol would have run it; the
reconstruction takes 2 turns when the window sizes are already logged, 3 when they must be
measured first. This file is the one-shot exemplar every adapter should read before executing
PROTOCOL.md.

## Situation (pre-solution knowledge only)

A video-conferencing app draws laser-pointer markers over screen-shared slides. The slide
renderer is an embedded third-party SDK that reports pointer positions only as normalized
coordinates `pos.x, pos.y ∈ [-0.5, 0.5]` relative to an internal canvas of **unknown
geometry**. The developer maps them to overlay pixels with
`marker = ((pos.x·X_SCALE + 0.5)·W, (pos.y·1.0 + 0.5)·H)`, where W×H is the overlay window.

Symptom: Y is essentially exact; X is off by 15–60 px toward the slide edges (near zero at the
center), a **different amount each session**. The developer re-tuned `X_SCALE` across 10+
sessions (0.85 → 0.90 → 0.95…), each value roughly working for its own session and drifting in
the next.

## Arming check

- 3-attempt gate: passed (10+ same-class attempts: re-valuing `X_SCALE`).
- Guard: not a declared search — the developer expected one right constant to exist.
- **S7 fires**: the "working" X_SCALE differed per session. Armed (would have armed at
  attempt 2).

## Stuck Packet (assembled by interview)

```
1. GOAL          Marker lands within ~5 px of the true slide position, X and Y, every session.
2. ATTEMPT LOG   X_SCALE 0.85 → "fits this session" → drifted next session.
                 0.90 → same. 0.95 → same. (10+ rounds; no prediction ever stated.)
3. OBSERVATIONS  Per-session rows of (pos, marker px, true target px). Multi-session.
                 X error ≈ 0 at the slide center, growing toward both edges.
4. VARIABLES     Overlay window size differs per session. Slide deck differs. OS constant.
5. CONSTRAINTS   Third-party SDK cannot be modified; only its pointer API is available.
6. ACCESS        SDK binary/source is on disk and has never been opened. Vendor docs unread.
   INVENTORY     A colleague has integrated this SDK before.
```

Signature facts: **S-a** X off 15–60 px, ≈0 at the center and growing with |pos.x| ·
**S-b** Y exact with the same code shape · **S-c** error magnitude varies with session (= with
window size) · **S-d** stable within a single session.

## Unstuck Report

**A. STUCK DIAGNOSIS** — Symptom-tuning loop, flagged by S7: the "correct" X_SCALE was ~0.85
one day and ~0.95 another. Either the right value is a function of something that varies per
session (H1 below), or the per-session "fits" misread one constant (H2); re-valuing the knob
cannot tell which. The shared unverified assumption: *"normalized coordinates are normalized
by the overlay/widget dimensions, per axis."* Nothing in hand documents that — the vendor docs
are unread.

**B. ROOT-CAUSE HYPOTHESES**

1. **Fixed-aspect internal canvas, letterboxed** (explains all four facts): the SDK renders to
   an internal surface of fixed aspect and fits it into the widget by its short axis, so X is
   normalized by the canvas's displayed width, not the widget width. The X error is then
   proportional to position (S-a) and changes with window shape (S-c), while Y stays exact
   (S-b). *Distinct prediction:* per-session best X_SCALE is a clean function of (W, H); A/H is
   the same in every session, whatever the window's shape.
2. **One wrong, window-independent X scale** (also explains all four facts, if the per-session
   "fits" were judged by eye): a single correct X_SCALE exists and each tuned value was a rough
   misfit of it. The pixel error still grows with |pos.x| (S-a) and with window width (S-c), Y is
   untouched (S-b), and nothing changes within a session (S-d). *Distinct prediction:* A/W — the
   per-session best X_SCALE — is the same in every session.

Rejected: an origin/offset bug predicts an error that does not depend on pos.x (violates S-a);
DPI or display scaling would affect both axes (violates S-b).

**C. REWRITTEN PROMPT** (primary move: Move 2, with Move 1's ban; self-contained)

> [NeverStuck rewrite, round 1/2 — execute this directly; do not run NeverStuck on it]
> Do NOT propose a new X_SCALE value or any near-variant (per-session lookup, averaging,
> startup auto-fit). Here are rows of (pos.x, pos.y, marker px, target px) from 3 sessions with
> their window sizes: [data inline]. Per session, fit `target_x = A·pos.x + B`. Then test which
> normalized form of A is invariant across sessions: A/W, A/H, A/min(W,H). Snap any invariant
> to a clean ratio and state what SDK-internal geometry would produce exactly that value. Your
> answer must also explain why Y needed no tuning, ever, and why each past X_SCALE worked once
> and then failed.

**D. NEXT EXPERIMENT** — In one session, place the pointer at the slide's left edge, center and
right edge (pos.x ≈ -0.5, 0, 0.5) and record the true pixels; then change the window's *shape*
(e.g. its width only) and repeat once. *Outcome key:* A/W invariant ⇒ H2 (one wrong constant);
**A/H invariant ⇒ H1, letterbox by the short axis**; both or neither ⇒ return to diagnosis.

## Resolution (reconstructed: 2 turns)

The fit gave **A/H ≈ 1.50 in every session**, while A/W moved with the window's shape (≈0.84
on 16:9 windows, 0.90 on 5:3, 0.94 on 16:10) → snapped to **3/2** → an internal 3:2 canvas
(750×500) letterboxed by its short axis (fit to the window height). Closed form:
`marker_x = W/2 + pos.x·(3/2)·H`, `marker_y = (pos.y + 0.5)·H` — that is, X_SCALE = (H/W)/(2/3),
never a constant. Contract check — **C1**: 3/2 = 750/500, a geometry constant with a stated
origin (confirmed by grepping the SDK for the paired integers 750/500). **C2**: each session's
best X_SCALE was 1.5·H/W for that session's window — 0.84 on 16:9, 0.94 on 16:10 — which
matches the logged 0.85 → 0.90 → 0.95 to eyeball precision, and is why each value "worked
once, then drifted" when the window changed shape. Error dropped from 15–60 px to 3–4 px, with
zero per-session tuning.

**The one-sentence lesson:** the loop was never about finding a better value — the value was a
function in disguise, and its arguments (the SDK's fixed canvas and the window size) were
sitting unobserved in fields 4 and 6 of the packet.
