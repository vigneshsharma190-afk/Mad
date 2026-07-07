# FWM Build System

This file turns the Fable Working Method (`.fable/README.md`) into a concrete
build system: named components, a build order, and an acceptance proof for
every stage. It derives **only** from the observed moves and skills FWM-1…5.
It shares nothing with `.moe/` — no skill cards, no agents, no invariants are
imported from there. Where the two systems would give different answers, this
file follows FWM.

**The design stance, restated as a build rule:** nothing in this system is
"built" when its code exists. A component is built when its passing case and
its failing case have both been demonstrated (FWM-1). Every stage below
therefore ends with a proof, not a deliverable list.

---

## 1. What the system is

A small toolchain, built in dependency order, that makes the seven moves
executable by anyone — a session, a different model, a human — without
having read the framework:

| # | Component | Embodies | Form |
|---|-----------|----------|------|
| 1 | `fable-state` | Move 1 — look before touching | read-only state snapshot script |
| 2 | `fable-proof` | Move 3 / FWM-1 — both-directions proof | test harness for checks |
| 3 | `fable-preflight` | FWM-5 — self-reference audit | pre-push scanner-vs-self runner |
| 4 | `fable-claim` | Move 5 / FWM-3 — smallest true claim | structured completion report |
| 5 | `fable-diagnose` | Move 4 / FWM-2 — live-state diagnosis | failure triage checklist runner |
| 6 | Exile ledger | Move 6 / FWM-4 — enforcement exile | tracked register of rule → mechanism |

Everything is plain shell + markdown, no dependencies, exit-code driven —
because FWM-4 says the load-bearing layer must run without anyone's judgment,
including mine.

What this system is **not** (per FWM §4): no orchestrator, no state machine,
no agent choreography, no retry counters. The moves compose by judgment; the
tools make each move cheap and its result checkable.

---

## 2. Build order and stage proofs

Stages are strictly ordered: each later component is proven *using* the
earlier ones. This is Move 2 (smallest verifiable step) applied to the build
itself — no stage starts until the previous stage's proof has run.

### Stage 0 — Ground truth

**Build:** nothing. Snapshot the environment before touching it (Move 1):
repository state, branch, remote, existing tooling, existing gates.

**Proof:** a written statement of current state that a second party could
falsify. If any later stage contradicts this snapshot, the snapshot was the
bug.

### Stage 1 — `bin/fable-state`

**Build:** a read-only script that prints the facts every task should check
before acting: current branch, sync with remote, dirty/clean tree, open PRs,
whether any required check exists on the target branch, and — critically —
*live* remote state (queried, not assumed; FWM-2's core lesson).

**Boundaries:** performs zero writes. Exit 0 = state printed; exit 2 = state
unavailable (not a pass — the FWM distinction between "verified" and
"unverifiable" is load-bearing).

**Proof (both directions):**
- PASS: run in this repo → correct branch/sync/PR facts, exit 0.
- FAIL: run outside any git repo → explicit "unverifiable" message, exit 2,
  and *no* fabricated facts.

### Stage 2 — `bin/fable-proof`

**Build:** the both-directions harness. Given a check command and a pair of
fixtures (`should-pass/`, `should-fail/`), it runs the check against both
and reports one of three verdicts:

- `PROVEN` — pass-case passed AND fail-case failed (exit 0)
- `UNPROVEN` — only one direction demonstrated (exit 1)
- `BROKEN` — pass-case failed, or fail-case passed (exit 1)

This encodes the FWM-1 corollary directly: *a check that has only ever
passed is unproven* — the harness refuses to say PROVEN without a
demonstrated failure.

**Proof (the harness must prove itself):**
- PASS: feed it a real check with correct fixtures → `PROVEN`.
- FAIL: feed it a tautological check (`true`) → the fail-fixture "passes,"
  harness reports `BROKEN`. If the harness certifies `true` as a valid
  check, the harness is the bug.

### Stage 3 — `bin/fable-preflight`

**Build:** the self-reference audit, mechanized. Before any push, run every
scanner/gate the repository owns **against the outgoing diff itself** —
including documentation — and report which gate would fire remotely.

This exists because the same blind spot bit twice (FWM §3.1, §3.2): I write
*about* patterns without registering that enforcement matches *strings*.
The tool asks the question I demonstrably forget to ask.

**Boundaries:** read-only over the diff; it advises, it does not modify.
Exemptions (e.g. "docs may describe a pattern without quoting it") must be
written next to their reasoning, never silently embedded.

**Proof:**
- PASS: run on a clean docs diff → no findings, exit 0.
- FAIL: run on a diff that quotes a gate's own trigger string → the finding
  names the exact gate that would fail remotely, exit 1. (This is the PR #6
  incident, converted into a fixture.)

### Stage 4 — `bin/fable-claim`

**Build:** the completion-report generator. After a task, it assembles the
*smallest true claim* from mechanical sources only:

- what changed (`git diff --stat` against the task's base)
- what was verified (which proofs/gates ran, with exit codes, verbatim)
- what was skipped or unverifiable (named as such, never omitted)
- what remains open (unmerged PRs, unpushed commits, TODO markers in diff)

The output template forbids the words "should," "probably," and "seems" in
the verified section — verified facts or nothing. Unverified statements go
in their own clearly-marked section.

**Proof:**
- PASS: run after a completed verified task → report matches reality when
  cross-checked by hand.
- FAIL: run mid-task with an unpushed commit and a skipped check → both
  appear in the report. If the report claims clean completion, the tool is
  the bug (this is completion pressure — FWM §3.5 — made mechanically
  impossible to indulge).

### Stage 5 — `bin/fable-diagnose`

**Build:** the failure-triage runner. On any failed external operation it
walks the FWM-2 sequence and *requires an answer at each step before
showing the next*:

1. What does the error text literally say? (paste it — not a paraphrase)
2. What is the system's live state? (command to query it — header, API,
   status; never the local cache)
3. What changed since it last worked? (or: has it ever worked?)
4. What new information would a retry carry? (if none → do not retry)
5. Is this an authorization boundary? (if yes → emit the exact command the
   resource owner must run, and stop)

**Boundaries:** step 5 is hard-coded to stop. The tool never suggests
credential workarounds; ownership boundaries end diagnosis by design.

**Proof:**
- PASS: replay the OAuth-scope failure from this repo's history through the
  checklist → it reaches step 5 and stops with the `gh auth refresh`
  handoff, exactly as the session actually did.
- FAIL: give it a transient failure (remote hangup) → step 4 identifies
  that a retry *does* carry new information, and it permits exactly that —
  demonstrating it doesn't just say "stop" to everything.

### Stage 6 — The exile ledger (`.fable/EXILE.md`)

**Build:** a tracked register with one row per rule that matters:

| Rule | Prose home | Mechanism | Proven by |
|------|-----------|-----------|-----------|

A rule may exist as prose only while its "Mechanism" cell is honestly
`none yet — prose only, will be bent`. The ledger makes the gap between
stated rules and enforced rules *visible* instead of discovered during
incidents. FWM-4's origin story — I broke my own written rule with a
justification — is the first entry.

**Proof:**
- PASS: every mechanism row cites a `fable-proof` PROVEN run.
- FAIL: grep the repo's prose rules (CLAUDE.md and equivalents) → any rule
  absent from the ledger is a finding. The ledger must catch at least one
  on first run, or it hasn't been honestly populated.

---

## 3. Safety rules for the build itself

These bind the *builder* (me or any session executing this plan):

1. **One stage per branch/PR.** No stage mixes with another; a failed stage
   isolates its own cause (Move 2).
2. **Read-only by default.** Components 1, 3, 4, 5 never write to the
   working tree; component 2 writes only inside its own fixture directory.
   Nothing in this system modifies `.moe/`, application code, or git state.
3. **The repo's existing gate still governs.** `bin/moe-verify.sh` runs
   before every commit of this build, and every PR must pass
   `verify-architecture-invariants` — this build adds tools, it does not
   replace or weaken the enforcement already exiled to GitHub.
4. **Fixtures live in scratch space or `.fable/fixtures/`,** never in
   application paths; deliberate-violation fixtures must be unmistakably
   named (`should-fail/`) and contain fake values only — a fixture with a
   real credential is a real leak (FWM-5's exemption reasoning).
5. **No stage is reported complete without its proof output attached** —
   `fable-claim` discipline applied before `fable-claim` exists.
6. **Stop conditions are honest:** if a stage's proof cannot be produced,
   the stage is reported UNPROVEN and the build pauses there. No skipping
   ahead on the assumption it'll work.

---

## 4. Acceptance: when is the system "built"?

Not when the six components exist. The system is built when this composite
proof passes:

1. `fable-state` correctly describes this repository (and refuses a
   non-repo).
2. `fable-proof` reports PROVEN for `moe-verify.sh` using pass/fail
   fixtures — the new system proving the old system, both directions.
3. `fable-preflight` catches a staged diff that would fail the remote gate,
   before push (the PR #6 class of failure, now impossible to hit blind).
4. `fable-claim` produces a report for the build itself in which every
   verified line is mechanically sourced.
5. `fable-diagnose` replays the OAuth incident to the correct stop.
6. `EXILE.md` has no silent prose-only rules.

Each item is a both-directions proof, so the acceptance run is itself the
final FWM-1 exercise. Until all six pass, the honest status of this system
is: **specified, not built** — exactly the distinction MOE's documentation
had to learn the hard way, applied to my own framework from day one.
