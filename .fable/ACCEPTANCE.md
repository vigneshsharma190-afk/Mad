# FWM Composite Acceptance Run

**Spec:** `.fable/BUILD.md` §4. **Run:** 2026-07-11, on `main` at `30ab8b5`
(all six stage PRs #10–#15 merged), macOS, plain zsh/bash, no dependencies.

Every item below is a both-directions proof: the expected PASS behavior and
the expected FAIL behavior were both demonstrated, with exit codes recorded
verbatim. Fixture work ran in session scratch space; nothing here modified
`.moe/`, `bin/`, or git state on `main` (BUILD.md §3).

**Defanging note (the PR #6 lesson, applied):** this document quotes strings
that the remote gate pattern-matches. Every such literal below is written
with a `[ ]` inserted (e.g. `flag [=] true`) so this record cannot itself
fire the gate it documents. `fable-preflight` was run on this file's own
diff to confirm — mechanically, not by the author's judgment.

---

## Item 1 — `fable-state` describes this repo, refuses a non-repo

**PASS direction:** `bin/fable-state` at repo root → exit 0. Reported
branch `main`, working tree clean, `in sync with origin (live-queried:
30ab8b5)`, `open PRs: none`, required check
`verify-architecture-invariants (on main, live-queried)`. Cross-checked by
hand against `git status` and `gh pr list` — both agree.

**FAIL direction:** run from an empty non-repo directory → exit 2, output:

```
UNVERIFIABLE — not a git repository. No facts can be reported.
Nothing below this line would be trustworthy, so nothing is printed.
```

Zero fabricated facts. **Item 1: PASS.**

## Item 2 — `fable-proof` reports PROVEN for `moe-verify.sh`

Fixtures: two scratch git repos with a baseline commit each.
`should-pass/` adds a harmless markdown file; `should-fail/` adds a fake
Stripe-shaped credential (`sk_live_` + `[FAKEFIXTUREVALUE…]`, fake value,
unmistakably inside `should-fail/` per BUILD.md §3.4).

```
$ fable-proof --check bin/moe-verify.sh --fixtures <scratch>/moe-verify
[pass-case] exit 0 in should-pass/ — as required
[fail-case] exit 1 in should-fail/ — as required
VERDICT: PROVEN — both directions demonstrated        (exit 0)
```

**Harness self-check (Stage 2's FAIL direction):** same fixtures with
`--check true` →

```
[fail-case] exit 0 in should-fail/ — check passed a case built to fail
VERDICT: BROKEN — check cannot detect the violation it exists to catch   (exit 1)
```

The new system proves the old system, and refuses a tautology. **Item 2: PASS.**

## Item 3 — `fable-preflight` catches a remote-gate-tripping diff before push

Run in a scratch clone on a throwaway branch (real tree untouched).

**FAIL direction:** commit a docs file containing the literal auth-bypass
flag `skipAuthCheck [=] true` (undefanged in the fixture) — the PR #6 class
of failure: prose quoting an enforcement string. Result, exit 1:

```
[WOULD FIRE] Gate 5 — multi-tenant authorization (scans ALL files incl. docs)
             docs-example.md:A dangerous flag looks like: `skipAuthCheck [=] true` — never ship this.
[BLOCKED-IF-PUSHED] 1 remote gate(s) would fire. Fix before push.
```

The finding names the exact remote gate, before any push happens.

**PASS direction:** clean docs-only diff → all four gates `[clear]`,
`[CLEAR] no remote gate would fire on this diff.`, exit 0. **Item 3: PASS.**

## Item 4 — `fable-claim` on the build itself, every VERIFIED line mechanical

```
$ fable-claim --base 0b85b03        # last commit before the FWM PRs
```

Exit 0. The VERIFIED section contained only command output: the
`git diff --stat` of the build (8 files, 1188 insertions — the five tools,
README, BUILD, EXILE) and gates run at report time
(`moe-verify.sh → exit 0`, `fable-preflight → exit 0`). No
should/probably/seems anywhere in it. Cross-checked the diff-stat by hand —
matches.

Honesty check: the OPEN section flagged four lines — the tools' own source
and spec quoting the words TODO/FIXME — and therefore concluded
`NOT settled: 1 open/unverified item(s)`. That is faithful string-matching
over-reporting rather than omission: the tool refused to say "done" about
its own build. Nothing real was missing from the report. **Item 4: PASS.**

## Item 5 — `fable-diagnose` replays the OAuth incident to the correct stop

**PASS direction (the historical incident, scripted via `--answers`):**
error text = the OAuth App `workflow`-scope push rejection; live-state
query = the `X-Oauth-Scopes` header check showing the scope absent;
retry-information = none; authorization boundary = yes. Result, exit 0:

```
HANDOFF — diagnosis ends at the ownership boundary.
    gh auth refresh -h github.com -s workflow
```

Identical stop and identical handoff command to what the original session
actually did (.fable/README.md, Move 4). No credential workaround offered.

**FAIL directions (it doesn't just say stop):**
- Transient remote hangup where the live query shows the remote reachable
  again → `RETRY-WITH-CHANGES — a retry is legitimate.` (exit 0).
- Same error with no live-state query and `none` new information →
  `DO-NOT-RETRY — a retry would carry no new information.` (exit 1).

**Item 5: PASS.**

## Item 6 — `EXILE.md` has no silent prose-only rules

Re-swept the ledger's declared sources (CLAUDE.md, `.moe/README.md` §3/§8,
`.fable/README.md`, `.fable/BUILD.md` §3) against the 17 rows.

**Findings (3) — the sweep worked, and acceptance required fixing them:**

1. **MOE invariant #3** (no schema change without matching migration files)
   had a live mechanism — `moe-verify.sh` Gate 3 — and **no ledger row**: a
   silent rule, the exact failure class this item exists to catch. Now
   row 18, with a fresh `fable-proof` **PROVEN** run for this acceptance:
   schema-change-with-migration → exit 0; schema-change-without →
   `[FAIL] Gate 3: Schema/migration lockstep (invariant #3)`, exit 1.
   The row also records the uncomfortable part: the remote CI gate has no
   lockstep counterpart — this invariant is local-only.
2. **Subagent/profile divergence rule** (CLAUDE.md: profile wins, subagent
   file must be updated) — prose only, unlisted. Now row 19.
3. **Component read-only rule** (BUILD.md §3.2) — prose only, unlisted.
   Now row 20.

Judgment calls made visible rather than silently excluded: CLAUDE.md's
"run `--full` periodically" is guidance without a never/always edge;
BUILD.md §3.5/§3.6 (proof-before-complete, honest stops) are the builder's
duties already represented by row 12's mechanism gap and exercised by this
document's own existence.

After the fixes: every mechanism row cites an actual firing or a
`fable-proof` PROVEN run; every unenforced rule carries the exact honest
phrase; no third state. **Item 6: PASS — with three findings caught and
closed, which is the item working as specified.**

---

## Composite verdict

All six items demonstrated in both directions. Per BUILD.md §4, the honest
status of the FWM system changes from *specified, not built* to **built**.

What this does **not** claim (rows 10–14, 19–20 of the ledger): the working
discipline around these tools — actually running them before commit/push —
remains unenforced prose. The tools are built and proven; nothing yet
*makes* anyone run them. That gap is recorded where it belongs, in the
exile ledger, as the next thing worth closing.
