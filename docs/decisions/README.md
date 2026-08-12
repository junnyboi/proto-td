# Decisions and Deviations

Use this directory for durable architectural choices and numbered deviations that another agent must honor. Do not duplicate transient implementation notes or manufacture retrospective decisions.

Name records `D-###-short-topic.md`. Each record must include:

1. **Status and date** — proposed, accepted, superseded, or retired.
2. **Context** — the concrete conflict, constraint, or failed assumption.
3. **Decision** — the selected behavior or exception in testable terms.
4. **Consequences** — affected contracts, compatibility, risks, and rollback path.
5. **Verification** — tests, scenarios, evidence, or human authority supporting the record.
6. **Supersession** — the successor record when the decision changes; never silently rewrite history.

Product behavior, protected thresholds, legal exceptions, and architecture pin breaks require explicit human or coordinator authority. Existing deviations that already have a canonical home, such as `D-SFX` in [`../../FEATURES.json`](../../FEATURES.json), stay there until a separately assigned migration preserves their history and references.
