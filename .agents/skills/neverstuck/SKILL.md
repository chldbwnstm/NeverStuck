---
name: neverstuck
description: >
  Escape repeated-failure loops in any domain. Use when the same fix class has
  failed 3+ times, when a fix "works then regresses" across sessions/contexts,
  when a constant is being tuned with no derivation, or when the user expresses
  frustration at repeated failed attempts ("still broken", "again", "we already
  tried this", "아직도 안 돼", "또 틀어져"). Do NOT use on a first or second
  failure, or for taste/preference iteration.
---

Read `PROTOCOL.md` (in this skill's directory, or at the repository root) and execute it
against the current conversation:

1. Run the arming check (3-attempt gate + guard + S7 exception). If not armed, say so and stop.
2. Assemble the Stuck Packet — mine the current conversation/transcript first, then interview
   the user for missing fields (max 5 questions, one message). Show the packet for correction.
3. Emit the 4-section Unstuck Report (A diagnosis / B hypotheses / C rewritten prompts /
   D exactly one experiment).
4. If this host has tools and the user agrees, run experiment D directly (log regression,
   grep, probe code) instead of leaving it on paper. Act on section D only.
5. Tag any hedged stopgap value in any answer as `[loop-bait — gated on D]`.

Read `examples/teampoint-laser-pointer.md` (if present) as a one-shot demonstration before
producing your first report. Respond in the user's language.
