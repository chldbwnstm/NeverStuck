---
name: neverstuck
description: >
  Escape repeated-failure loops in any domain. Use when the same fix class has
  failed 3+ times, when a fix "works then regresses" across sessions/contexts,
  when a constant is being tuned with no derivation, or when the user expresses
  frustration at repeated failed attempts ("still broken", "again", "we already
  tried this", "아직도 안 돼", "또 틀어져"). Do NOT use on a first failed attempt,
  on a second one unless the working value already differed between contexts
  (S7), for taste/preference iteration, or on a prompt that starts with a
  "[NeverStuck rewrite" marker (execute that prompt instead).
---

Read NeverStuck's `PROTOCOL.md` (its first line is `# NeverStuck Protocol`) in this skill's
directory, or at the root of a NeverStuck checkout, and execute it against the current
conversation. If you cannot find it, or the file you find is not the NeverStuck protocol, do
not improvise the protocol: tell the user the install is incomplete — a complete install is
one folder holding this `SKILL.md`, `PROTOCOL.md` and `examples/teampoint-laser-pointer.md` —
and stop.

1. Run the arming check (3-attempt gate + guard + S7 exception). If not armed, say so (for a
   matter of taste: that NeverStuck does not apply), give ordinary one-shot advice, and stop.
   (A prompt that starts with the rewrite marker: just execute it.)
2. Assemble the Stuck Packet — mine the current conversation/transcript first. If fields are
   missing or the guard is unsettled, send one message with the draft packet and at most 5
   questions (the guard question counts), then wait for the answers. If no one can answer
   (non-interactive run, subagent), mark each assumption ASSUMED instead of asking (an
   unsettled guard counts as "no declared search").
3. Emit the 4-section Unstuck Report (A diagnosis / B hypotheses / C rewritten prompts /
   D exactly one experiment). Start each rewrite in C with the marker line from PROTOCOL.md.
4. If this host has tools and the user agrees, run experiment D directly (log regression,
   grep, probe code) instead of leaving it on paper. Act on section D only.
5. Tag any hedged stopgap value for a banned or S7 knob exactly as PROTOCOL.md's stopgap rule
   says: `[loop-bait — this value will drift again; gated on the experiment in D]`.

Read `examples/teampoint-laser-pointer.md` (if present) as a one-shot demonstration before
producing your first report. Respond in the user's language.
