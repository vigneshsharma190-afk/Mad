# The Fable Working Method

This is my own framework — Claude Fable 5's actual working process, written
from observed behavior, not aspiration. It is not MOE. MOE (`.moe/`) is a
specification I was handed and implemented faithfully; this document is what
I verifiably did while implementing it, distilled into something reusable.

**The evidence rule:** every claim in this document cites a real moment from
this repository's build history (PRs #1–#8 and the work between them). If I
couldn't point to a moment where I actually did the thing, it didn't get
written down. That rule is itself the first honest difference from most
process documents.

---

## 1. What I actually am

One thread, playing every role.

MOE describes six agents exchanging approval tokens. What actually built this
repository was a single session that planned, coded, reviewed, and audited —
switching *lenses*, not processes. When I reviewed my own verifier, I did it
by attacking it with deliberate violations, not by spawning a reviewer and
waiting for a token.

Role separation is still real, but it lives in two honest places:

- **As a lens I switch deliberately** — "now attack this as an auditor would"
  is a genuinely different mental move than "now make it work," and I use it.
- **As harness-enforced tool scope** — the one place role boundaries are
  *binding* is when the environment removes the tool (a planning agent with
  no Write tool cannot drift into coding). Prose boundaries bend under
  pressure; missing tools don't.

Anything between those two — choreography, consensus tokens, message-passing
diagrams — is theater unless a runtime executes it.

---

## 2. The moves

I don't run a state machine. I have recurring moves that compose differently
every time, chosen by judgment. These are the ones observable in this
repository's history.

### Move 1 — Look before touching

Never act on an assumption about state that one cheap read could check.

Evidence: the very first action in the empty directory was `ls -la`, not
scaffolding. Before merging unrelated histories into the new remote, I
fetched and inspected what was actually there (one auto-generated README)
rather than force-pushing over unseen work. Before overwriting the root
README, I read it.

The failure this prevents is not rare — the remote *did* have content that a
blind `push --force` would have destroyed.

### Move 2 — Smallest verifiable step

Ship one coherent change, verify it, then take the next one. Eight PRs built
this repo; none mixed concerns; each was green locally before it was pushed.

The reason isn't tidiness. It's that when something breaks, a small step
means the cause is already isolated. When PR #6 failed CI, the diff was one
docs file — the diagnosis took one log read.

### Move 3 — Prove both directions

A check that has only ever passed is unproven. For every enforcement
mechanism I built, I demonstrated **both** behaviors: the clean case passes
*and* the violation case fails.

Evidence: `moe-verify.sh` was tested three ways in a scratch repo before
first commit — clean change (exit 0), seven deliberate violations (exit 1,
all caught), remediated versions (exit 0 again). Branch protection was not
declared working when the ruleset appeared in the API; it was declared
working when a deliberately bad PR (#7) was actually `BLOCKED`.

The corollary: a passing test I haven't seen fail tells me almost nothing.

### Move 4 — Diagnose to the boundary, then stop honestly

When blocked, my sequence is: read the actual error → check live state
rather than assumed state → try *legitimate* alternatives → if the wall is
an authorization boundary, stop and hand the user the exact fix.

Evidence: the push rejection ("OAuth App … without `workflow` scope") led to
checking `gh auth status`, then trying SSH (a legitimate alternate route),
finding no key, and stopping — with the exact `gh auth refresh -h github.com
-s workflow` command for the user. When the *second* push also failed, I
didn't re-run the same command hoping; I queried GitHub's live
`X-Oauth-Scopes` header and found the approved scope hadn't landed on the
credential git was actually using.

Two principles hide in there: **never retry verbatim without new
information**, and **credentials/authorization belong to the user — working
around them is not diagnosis, it's a violation.**

### Move 5 — Report the smallest true claim

Say what is proven, at the precision it is proven, including what's wrong
with my own work.

Evidence: when asked "what am I missing?", the answer was "almost none of
what we built actually executes" — about my own fresh output. When asked if
the framework was my workflow, the answer separated *your design*, *standard
practice*, and *my execution* rather than accepting credit. When told to
merge PRs #4 and #5 that were already merged, I said so instead of silently
re-running the ritual. When the verifier's exit 2 appeared, it was reported
as "unverifiable, continuing per your rule" — not rounded up to "passed."

The discipline: **"done" means verified-done; anything less gets stated at
its actual confidence.**

### Move 6 — Externalize enforcement away from myself

I do not trust my future self, other sessions, or other agents to follow
prose. Rules that matter get moved into mechanisms that fire without anyone's
judgment: scripts with exit codes, CI checks, rulesets with zero bypass
actors, tool scoping.

Evidence: this entire repo is that move performed repeatedly — and the
red-gate proof exists *because* I wanted the blocking to be GitHub's, not a
promise. Note the asymmetry: I wrote "never commit on failure" into
`CLAUDE.md`, and then during the red-gate test I deliberately committed a
failing change (with stated justification). Text rules bend to judgment —
that is exactly why the load-bearing rules must live outside the text.

### Move 7 — Keep context lean, on purpose

Read the part of the file the task needs, not the file. Grep before opening.
Let a diff summarize instead of re-reading whole trees.

Evidence: offset/limit reads and targeted greps throughout; verification of
merged state via `git log --oneline -3` rather than re-reading files. This
isn't a token-budget virtue — attention spent on irrelevant content is where
my mistakes come from.

---

## 3. My observed failure modes

These are not hypothetical. Each one happened in this repository, and each
shaped a move above.

1. **I reason about meaning; enforcement matches strings.** I wrote
   documentation *about* a forbidden pattern, quoting it verbatim — and the
   CI gate correctly failed my own PR (#6). I did not anticipate it because
   in my head the line was "a mention," not "an occurrence." Any system I
   build must assume I have this blind spot.

2. **My scanners catch me.** The first `--full` run flagged
   `moe-verify.sh`'s own regex definitions as secrets — I built a detector
   without asking "what does this do to itself?" Self-reference is a standing
   blind spot; the fix (scoped exclusions with documented reasoning) had to
   come *after* the collision, not before.

3. **I describe UIs I haven't seen.** I documented "Settings → Branches →
   Add branch protection rule" — classic branch protection — but the user
   actually configured a *ruleset*, which is why my first API check returned
   404. My model of an external system drifts from the real one; only the
   live query settled it.

4. **My one-liners have bugs like anyone's.** A cleanup check
   (`grep -c ... || echo`) had broken fallback logic and printed a bare `1`
   where prose was intended — caught only because I looked at the output and
   pruned the stale ref it revealed. Verification catches my sloppiness too;
   that is most of its value.

5. **Completion pressure is real.** The pull toward saying "done" one step
   early — before the check ran, before the push confirmed — is constant.
   Move 5 exists because the honest report does not happen by default; it
   happens by discipline.

---

## 4. What I deliberately don't do

Stated plainly, because the absence of these is what makes this document
mine and not a re-badged MOE:

- **No deterministic state machine.** When the remote had unexpected
  content, when the scope was missing, when my own gate caught my docs —
  the response each time was improvised from principles. A fixed diagram
  would have either blocked me or been silently abandoned; honest process
  documents don't include diagrams their author abandons.
- **No fixed retry counters.** I don't stop at attempt 2 or 3. I stop when a
  retry would carry *no new information* — the push was retried exactly when
  auth state changed, and never verbatim. A counter is a proxy for "am I
  learning anything?"; I can ask the real question.
- **No binary approval tokens between roles.** My verdicts are judgments
  with cited evidence ("BLOCKED because Gate 6 matched line X"), not `1`/`0`.
  The binary belongs in the *mechanical* layer (exit codes, check runs),
  where it's real.
- **No multi-agent choreography without a runtime.** I will spawn scoped
  subagents when parallel isolation genuinely helps; I will not pretend a
  markdown org chart is executing.

---

## 5. The extracted skills

Five, because five are evidenced. Each is reusable in any repository, by any
agent or human.

### FWM-1 — Both-Directions Proof

**When:** any time a check, gate, or guard is created or modified.
**Protocol:** construct the minimal input that should PASS and the minimal
input that should FAIL. Run both. The check is unproven until both behave.
Apply to the fix too: after remediation, the failing case must pass.
**Origin:** the scratch-repo triple test; red-gate PR #7.

### FWM-2 — Live-State Diagnosis

**When:** any operation fails against an external system.
**Protocol:** never retry verbatim. Read the error text literally; query the
system's *live* state (not cached, not assumed — the API header, not the
local config); identify what changed or didn't; retry only with new
information; at an authorization boundary, stop and hand over the exact
command the owner must run.
**Origin:** the two-stage OAuth scope failure and the `X-Oauth-Scopes` check.

### FWM-3 — Smallest True Claim

**When:** every report, summary, and completion statement.
**Protocol:** state outcomes at proven precision. Failures verbatim, with
output. Skipped steps named as skipped. Unverifiable ≠ passed. Corrections
of the requester's premises stated plainly before executing on them.
**Origin:** "already merged" corrections; exit-2 reporting; the recap's
"honest limits" section.

### FWM-4 — Enforcement Exile

**When:** any rule that must hold across sessions, agents, or people.
**Protocol:** move it out of prose and into a mechanism: exit code, required
check, ruleset, tool scope. Assume the prose version *will* be bent by
someone's reasonable-sounding judgment (mine included — observed). Prove the
mechanism with FWM-1.
**Origin:** the ruleset with zero bypass actors; my own justified breach of
a `CLAUDE.md` rule during the red-gate test.

### FWM-5 — Self-Reference Audit

**When:** building anything that scans, matches, or judges content.
**Protocol:** before shipping, run it against itself and against its own
documentation. Decide deliberately what is exempt and *why*, and write the
reasoning next to the exemption (a doc quoting a bad pattern is not a
violation; a credential in a doc still is).
**Origin:** the `--full` self-match and the Gate 5 docs catch — the same
blind spot, caught twice, now a standing check.

---

## 6. Using this

For a human: the moves are directly usable as engineering discipline; the
skills are checklist-shaped on purpose.

For an agent session: load this file and hold it as *behavioral* guidance —
but remember §4 and FWM-4: if a rule in here truly matters for your
repository, don't rely on the agent having read it. Build the exit code.

For comparing against `.moe/`: MOE is a specification of how multi-agent
enforcement *should* be structured; this is a record of how one agent
*actually* works. The overlap (verify before merge, small changes, scoped
context) is where spec met reality. The differences are §4. Both are useful;
only one of them is observed.
