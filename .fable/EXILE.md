# Exile Ledger

The FWM-4 register: every rule that matters, and whether it lives in a
mechanism that fires without anyone's judgment — or only in prose, where it
*will* eventually be bent by someone's reasonable-sounding justification
(observed: the red-gate test itself broke a written rule, with justification).

A row's Mechanism cell is either a real, named enforcement point or the
honest phrase `none yet — prose only, will be bent`. No third state. "Proven
by" must cite an actual run where the mechanism fired (or a `fable-proof`
PROVEN verdict) — configuration existing is not proof.

Sources swept for prose rules: `CLAUDE.md`, `.moe/README.md` §3/§8,
`.fable/README.md`, `.fable/BUILD.md` §3.

| # | Rule | Prose home | Mechanism | Proven by |
|---|------|-----------|-----------|-----------|
| 1 | No merge into `main` without passing `verify-architecture-invariants` | CLAUDE.md; .moe §8 | GitHub ruleset `main`, required check, zero bypass actors | Red-gate PR #7: check failed → `mergeStateStatus: BLOCKED` |
| 2 | No direct pushes to `main` | CLAUDE.md; .moe §8 | Same ruleset: PR required before merging | Ruleset live-queried (rules API); direct-push path closed since |
| 3 | No force pushes / branch deletion on `main` | — (ruleset only) | Same ruleset: non_fast_forward + deletion rules | Ruleset live-queried; not exercised — deliberately (a proof would require attempting a destructive act) |
| 4 | No hardcoded secrets/credentials in changes | .moe §3 inv.2 | `moe-verify.sh` Gate 2 + CI Gate 2 | fable-proof PROVEN run (Stage 6); scratch-repo test caught `sk_live_` fixture |
| 5 | No implicit `any` in TypeScript changes | .moe §3 inv.1 | `moe-verify.sh` Gate 1 + CI Gate 1 | Scratch-repo test caught `: any` fixture; CI direction unexercised on real TS (no TS in repo yet) |
| 6 | No unsafe destructive migrations without expand-and-contract | .moe §3 inv.5 | `moe-verify.sh` Gate 3b + CI Gate 3 | Scratch-repo test caught `DROP COLUMN` fixture |
| 7 | No new DB entity without RLS migration | .moe §3 inv.4 | `moe-verify.sh` Gate 4 + CI Gate 4 | Scratch-repo test caught missing-RLS fixture |
| 8 | No unmasked PII into logging sinks | .moe §3 inv.6 | `moe-verify.sh` Gate 5 + CI (partial) | Scratch-repo test caught `console.log(email)` fixture |
| 9 | No multi-tenant authorization bypass flags | .moe §3 inv.7 | `moe-verify.sh` Gate 6 + CI Gate 5 | PR #6: CI gate fired on real outgoing docs — the mechanism caught its own author |
| 10 | Run `moe-verify.sh` before every commit | CLAUDE.md | none yet — prose only, will be bent | — (observed bent already: red-gate test committed a failing change with justification) |
| 11 | Never commit/push when the local gate fails | CLAUDE.md | none yet — prose only, will be bent | — (same breach as #10; GitHub's remote gate is the backstop, but the local rule itself is unenforced) |
| 12 | Report verification status before finalizing any task | CLAUDE.md | `fable-claim` exists, but nothing *requires* running it — prose only, will be bent | — |
| 13 | Preflight the outgoing diff before push | .fable/BUILD.md §2.3 | `fable-preflight` exists, but nothing *requires* running it — prose only, will be bent | — |
| 14 | One stage per branch/PR; no combined stages | .fable/BUILD.md §3.1 | none yet — prose only, will be bent | — (held by discipline through PRs #10–#15, which is exactly what this ledger says not to trust) |
| 15 | Fixtures contain fake values only | .fable/BUILD.md §3.4 | Partially mechanized: Gate 2 patterns would catch realistic-format secrets in tracked fixtures; fake-but-plausible values rely on prose | Gate 2 proofs (row 4) cover the credential-shaped subset |
| 16 | Load the matching agent profile before role-scoped work | CLAUDE.md | Tool scoping in `.claude/agents/*` frontmatter binds *spawned* subagents; the main session honoring profiles is prose only | Frontmatter is declarative config; unexercised — no subagent spawned in anger yet |
| 17 | Read `.moe/README.md` before planning or editing | CLAUDE.md | none yet — prose only, will be bent | — (caught by this ledger's own first-run sweep — the row you are reading exists because the cross-check found it missing) |
| 18 | No schema change without matching migration files | .moe §3 inv.3 | `moe-verify.sh` Gate 3 — local only; the remote CI gate has **no** lockstep counterpart | fable-proof PROVEN run (acceptance, 2026-07-11): schema-change-with-migration passed, schema-change-without failed on Gate 3. Row exists because the acceptance-item-6 sweep caught it missing — the ledger's second self-catch |
| 19 | Subagent files in `.claude/agents/` must match their `.moe/profiles/` profile; profile wins on divergence | CLAUDE.md | none yet — prose only, will be bent | — (caught by the acceptance-item-6 sweep) |
| 20 | FWM components are read-only outside their own fixture dirs; nothing modifies `.moe/`, app code, or git state | .fable/BUILD.md §3.2 | none yet — prose only, will be bent | — (caught by the acceptance-item-6 sweep; held so far by code review of PRs #10–#15) |

## Reading this honestly

Rows 10–14 and 19–20 are the ledger's point: the repository's own working
discipline — verify-before-commit, preflight-before-push, one-stage-per-PR,
subagent/profile consistency, component read-only-ness — is currently
**unenforced prose**, held up only by the operator behaving well. The
remote ruleset (rows 1–2) is what actually protects `main` when that
behavior lapses. Row 18 is narrower but real: invariant #3 is enforced
locally only, so a direct-to-PR change skipping the local gate would reach
CI with no lockstep check at all.

Closing a prose-only row means building its mechanism (a pre-commit hook for
row 10/11, a pre-push hook for row 13, a CI shape-check for row 14), proving
it with `fable-proof`, and updating the row — not rewording the rule.
