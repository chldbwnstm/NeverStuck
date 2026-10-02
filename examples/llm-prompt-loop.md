# Worked Example — LLM Prompt Loop (dogfooding: the stuck thing is a prompt)

The knob here is *wording*. This is the case where NeverStuck applies to the very activity it
lives in — prompt engineering — and where the fact-of-the-matter boundary matters.

## Situation

A pipeline asks a model to emit strict JSON. It fails validation on ~15% of inputs. The
developer has rewritten the instruction four times ("Output ONLY JSON", ALL-CAPS warnings,
threats, a pleading example). Each rewrite seemed to help on the test inputs, then failures
returned in production.

## Arming check

4 same-class attempts (re-wording the same instruction) ✓. Guard: there IS a fact of the
matter (valid JSON is objective — this is not a taste domain) ✓. **S7 analog**: the wording
that "works" differs between test and production inputs ⇒ wording is standing in for an
unmodeled function of the input. Armed.

## Stuck Packet (key fields)

```
2. ATTEMPT LOG   4 rewrites; each validated on the 20-case dev set, regressed in production.
3. OBSERVATIONS  Failure samples: prose preamble before the JSON ("Here is the JSON you..."),
                 mostly on LONG inputs. Short inputs almost never fail.
4. VARIABLES     Input length (dev set median 300 tokens; production up to 6k).
                 Instruction sits at the TOP of the prompt; input is appended after.
5. CONSTRAINTS   Model version fixed this quarter; no fine-tuning.
6. ACCESS        Provider docs on response formatting / prefilling — unread.
```

Signature facts: **S-a** ~15% invalid JSON · **S-b** short inputs are fine with the *same*
wording · **S-c** failure rate grows with input length · **S-d** does not vary with wording
strength (4 rewrites, same production rate).

## Unstuck Report (condensed)

**A.** Symptom-tuning loop; shared unverified assumption: *"compliance is a function of how
forcefully the instruction is phrased."* S-d falsifies it directly.

**B.** H1 **Instruction distance**: the instruction is at the top; on long inputs it is
thousands of tokens away from the generation point — predicts failures concentrate on long
inputs regardless of wording (matches S-b/S-c/S-d), and that moving the instruction next to the
generation point removes them. H2 **Missing structural constraint**: nothing forces the reply
to start as JSON, and long document-like inputs pull the opening tokens toward prose ("Here is
the JSON you…") — also fits S-a..S-d, but predicts the failures survive moving the instruction
next to the generation point. H3 Sampling temperature — predicts uniform failures across
lengths, rejected by S-c.

**C.** (Move 1) "[NeverStuck rewrite, round 1/2 — execute this directly; do not run NeverStuck
on it] Do not reword the instruction again. Explain why 4 rewrites each passed
the dev set and regressed in production — your mechanism must use the fact that the dev set is
short and production is long. Then propose fixes that change the *structure* of the request,
not the phrasing."

**D.** One experiment on long inputs only (S-c already settles length): the same wording, with
the instruction at the top vs adjacent to the generation point, no other change, 50 samples per
arm. *Adjacent brings long-input failures down to the short-input rate ⇒ H1; leaves them within
noise of the top arm ⇒ H2; anything in between ⇒ both hold (compose).* (A prefilled `{` would
remove the preamble under either hypothesis, so it is a candidate fix, not a test.)

## Resolution

Moving the instruction next to the generation point cut long-input failures by ~70% — well
below the top arm, still above the short-input rate ⇒ both hold, and the fixes compose (the
residual preambles are consistent with H2). Fix:
instruction moved adjacent to the generation point + a structural constraint on the reply's
first token — a prefilled `{`, or structured outputs (which enforce the JSON shape) on APIs that
reject assistant prefill, as newer Claude models do (e.g. Opus 4.6 and later, Sonnet 5) —
**C1** ✓ derived from the attention/structure mechanism, not from wording taste; **C2** ✓
retro-predicts why every rewrite "worked" on the short dev set (distance was never the tested
variable). The wording itself was reverted to the original polite sentence.

**Boundary note:** had the goal been "make the JSON *field names prettier*", the guard would
have stopped the protocol — no fact of the matter, no derivable model, no arming.
