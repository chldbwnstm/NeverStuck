# Worked Example — TeamPoint Laser Pointer (the motivating case)

A real incident: 10+ failed tuning sessions, closed in 2 turns once the protocol's moves were
applied. This file is the one-shot exemplar every adapter should read before executing
PROTOCOL.md.

## Situation (pre-solution knowledge only)

A video-conferencing app draws laser-pointer markers over screen-shared slides. The slide
renderer is an embedded third-party SDK that reports pointer positions only as normalized
coordinates `pos.x, pos.y ∈ [-0.5, 0.5]` relative to an internal canvas of **unknown
geometry**. The developer maps them to overlay pixels with
`marker = ((pos.x·X_SCALE + 0.5)·W, (pos.y·1.0 + 0.5)·H)`.

Symptom: Y is essentially exact; X is off by 15–60 px, a **different amount each session**.
The developer re-tuned `X_SCALE` across 10+ sessions (0.85 → 0.90 → 0.95…), each value roughly
working for its own session and drifting in the next.

## Arming check

- 3-attempt gate: passed (10+ same-class attempts: re-valuing `X_SCALE`).
- Guard: not a declared search — the developer expected one right constant to exist.
- **S7 fires**: the "working" X_SCALE differed per session ⇒ the knob is an unmodeled function
  of something that varies per session. Armed (would have armed at attempt 2).

## Stuck Packet (assembled by interview)

```
1. GOAL          Marker lands within ~5 px of the true slide position, X and Y, every session.
2. ATTEMPT LOG   X_SCALE 0.85 → "fits this session" → drifted next session.
                 0.90 → same. 0.95 → same. (10+ rounds; no prediction ever stated.)
3. OBSERVATIONS  Per-session rows of (pos, marker px, true target px). Multi-session.
4. VARIABLES     Overlay window size differs per session. Slide deck differs. OS constant.
5. CONSTRAINTS   Third-party SDK cannot be modified; only its pointer API is available.
6. ACCESS        SDK binary/source is on disk and has never been opened. Vendor docs unread.
   INVENTORY     A colleague has integrated this SDK before.
```

Signature facts: **S-a** X off 15–60 px · **S-b** Y exact with the same code shape ·
**S-c** error magnitude varies with session (= with window size) · **S-d** stable within a
single session.

## Unstuck Report

**A. STUCK DIAGNOSIS** — Symptom-tuning loop on an unknown constant, proven by S7: the
"correct" X_SCALE was ~0.85 one day and ~0.95 another; a true mapping constant cannot need
per-session values. The shared unverified assumption: *"normalized coordinates are normalized
by the overlay/widget dimensions, per axis."* The SDK docs never say that.

**B. ROOT-CAUSE HYPOTHESES**

1. **Fixed-aspect internal canvas, letterboxed** (explains all four facts): the SDK renders to
   an internal surface of fixed aspect and scales it into the widget by one axis; X coordinates
   are normalized by a different denominator than the widget width, so X error is proportional
   to position and changes with window shape, while Y stays exact.
   *Distinct prediction:* per-session best X_SCALE is a clean function of (W, H).
2. Origin/offset bug — rejected: predicts a position-independent error (violates S-a growing
   with |pos.x|) and cannot explain S-c.
3. DPI/display scaling — rejected: would affect both axes (violates S-b).

**C. REWRITTEN PROMPT** (Move 1 + Move 2, self-contained)

> Do NOT propose a new X_SCALE value or any near-variant (per-session lookup, averaging,
> startup auto-fit). Here are rows of (pos.x, pos.y, marker px, target px) from 3 sessions with
> their window sizes: [data inline]. Per session, fit `target_x = A·pos.x + B`. Then test which
> normalized form of A is invariant across sessions: A/W, A/H, A/min(W,H). Snap any invariant
> to a clean ratio and state what SDK-internal geometry would produce exactly that value. Your
> answer must also explain why Y needed no tuning, ever, and why each past X_SCALE worked once
> and then failed.

**D. NEXT EXPERIMENT** — In one session, place the pointer at known normalized positions
(-0.5, 0), (0, 0), (0.5, 0) and record the true pixels; resize the window and repeat once.
*Outcome key:* A/W invariant ⇒ plain scale bug (H2-family); **A/H invariant ⇒ H1 letterbox by
the short axis**; neither ⇒ return to diagnosis.

## Resolution (2 turns)

The fit gave A/W ≈ 0.667 in every session → snapped to **2/3** → an internal 3:2 canvas
(750×500) letterboxed by its short axis. Closed form: `fx = pos.x·(2/3) + 0.5`,
`fy = pos.y + 0.5`. Contract check — **C1**: 2/3 = 500/750, a geometry constant with a stated
origin (confirmed by grepping the SDK for the paired integers 750/500). **C2**: every past
tuned value was that session's accidental curve-fit conflating the true constant with the
session's window shape — which is exactly why each "worked once, then drifted." Error dropped
from 15–60 px to 3–4 px, with zero per-session tuning.

**The one-sentence lesson:** the loop was never about finding a better value — the value was a
function in disguise, and its arguments (the SDK's fixed canvas and the window size) were
sitting unobserved in fields 4 and 6 of the packet.
