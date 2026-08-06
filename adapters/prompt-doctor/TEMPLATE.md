# NeverStuck — Prompt Doctor Template (paste into any chat model)

Zero installation. Works in any chat UI with any model.

## How to use

1. Paste the **entire contents of `PROTOCOL.md`** into the chat.
2. Below it, paste this template with the blanks filled (or just your raw failure
   transcript — the model will interview you for the rest).
3. Send. You should get back a 4-section UNSTUCK REPORT.

---

## Template

```
Execute the NeverStuck protocol above on the following problem.
Use only the information I provide here and in your interview — do not assume
facts I did not state. Interview me for missing packet fields (max 5 questions,
one message) before emitting the report. Answer in my language.

STUCK PACKET (fill what you know; write "unknown" freely)
1. GOAL: <what you are trying to achieve + how you'd measure success>
2. ATTEMPT LOG: <each thing you tried, in order, and what happened —
   especially any "worked, then broke again later">
3. OBSERVATIONS: <raw evidence: logs, error text, (input, expected, actual)
   examples — from more than one run/session if you have them>
4. VARIABLES: <what differs between the times it worked and the times it
   didn't — size, machine, timing, input, version>
5. CONSTRAINTS: <what cannot be changed>
6. ACCESS INVENTORY: <what you could inspect but haven't — source, docs,
   binaries, logs, a person who knows this component>

RAW TRANSCRIPT (optional — paste the failing conversation/attempts here):
<...>
```

## Pass criteria (how you know it worked)

The reply must contain sections **A/B/C/D**; section B hypotheses must be mechanisms (models),
not values; section C must NOT contain a new value for the knob you were tuning; section D must
be exactly ONE experiment with predicted outcomes per hypothesis. If you instead got another
tuned value — the model ignored the protocol; re-paste PROTOCOL.md and try once more, or switch
models.
