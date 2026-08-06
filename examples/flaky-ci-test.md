# Worked Example — Flaky CI Test (non-numeric domain)

Shows the protocol on a knob that is not a mapping constant: a timeout.

## Situation

`test_order_export` fails intermittently in CI (~2 runs in 5). The developer has raised its
timeout three times: 5 s → 10 s → 20 s. Each raise "fixed" it for a few days; failures
returned. It never fails locally.

## Arming check

3 same-class attempts (re-valuing the timeout) ✓. Not a declared search ✓. **S7 analog**: the
timeout that "works" differs by context (any value works locally; no value stays sufficient in
CI) ⇒ the knob is standing in for an unmodeled function of the environment. Armed.

## Stuck Packet (key fields)

```
2. ATTEMPT LOG   5s → passed 4 days, failed again. 10s → passed ~1 week, failed. 20s → still
                 fails ~1 in 10. No prediction ever stated.
3. OBSERVATIONS  CI logs: failures are assertion mismatches on row COUNTS (expected 120, got
                 117) — NOT TimeoutError. Local runs: always 120.
4. VARIABLES     CI runs the full suite in parallel shards; locally the test runs alone.
                 Shard composition changes per commit.
5. CONSTRAINTS   Cannot disable parallelism suite-wide.
6. ACCESS        Test source and fixtures readable; CI shard assignment logs available, unread.
```

Signature facts: **S-a** intermittent count mismatch · **S-b** the same test is deterministic
alone · **S-c** fails only in the parallel suite, rate varies with shard composition ·
**S-d** does not vary with the timeout value (20 s still fails).

## Unstuck Report (condensed)

**A.** Symptom-tuning loop; the shared unverified assumption: *"the failure is slowness."* The
observations contradict it — failures are wrong counts, not timeouts. The knob being tuned is
not even on the causal path.

**B.** H1 **Shared mutable state**: another test in the same shard writes the same table/fixture;
predicts failure co-occurs with specific sibling tests, and passes when run alone (matches
S-b/S-c). H2 Resource contention/slow DB: predicts TimeoutError, not count mismatch — rejected
by S-a. H3 True race inside the code under test: predicts occasional local failure too —
weakened by S-b.

**C.** (Move 1) "Do not change the timeout or add retries. Explain why 5→10→20 s each seemed to
work briefly — your mechanism must retro-predict that pattern." *(Retro-prediction under H1:
raising the timeout changed test scheduling enough to shuffle shard composition for a while —
an accidental, unstable fix, which is exactly what was observed.)*

**D.** One experiment: run `test_order_export` pinned into the same shard as each of its 6
sibling tests, one at a time. *Failure with sibling `test_bulk_import` ⇒ H1 (shared table);
failure with none ⇒ revisit H3 with a seeded scheduler.*

## Resolution

Pinning reproduced the failure 10/10 with `test_bulk_import` — both write `orders_tmp` without
isolation. Fix: per-test schema isolation. **C1** ✓ derived from the observed mechanism, not
fitted. **C2** ✓ explains every timeout raise "working briefly." The timeout went back to 5 s.
