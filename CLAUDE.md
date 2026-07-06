# MOE — Claude Code Project Rules

This repository runs under the MOE (Master Orchestrator Engine) framework.
These rules are mandatory for every session.

## Framework source of truth

- Read `.moe/README.md` before planning or editing anything.
- `.moe/` is the source-of-truth framework documentation. If guidance here
  and there ever conflicts, `.moe/README.md` wins.
- Before performing planning, coding, reviewing, maintaining,
  structural-integrity, or compliance/security work, load the matching agent
  profile from `.moe/profiles/` and operate within its stated boundaries and
  failure-mode watchlist.
- Real, spawnable project subagents live in `.claude/agents/` (one per MOE
  role, with scoped tool access). Prefer spawning them via the Agent tool for
  role-bounded work. `.moe/profiles/` remains the source-of-truth
  documentation layer — if a subagent file and its profile diverge, the
  profile wins and the subagent file must be updated to match.

## Verification discipline

- Run `./bin/moe-verify.sh` before every commit.
- Run `./bin/moe-verify.sh --full` for a whole-repository invariant sweep
  (all tracked + untracked files, not just the diff) — use it after adopting
  MOE in an existing codebase, after merges, or as a periodic audit.
- Never commit or push if `./bin/moe-verify.sh` fails (exit code 1).
  Exit code 2 means the environment cannot be verified — resolve that before
  proceeding, don't treat it as a pass.
- Report the local verification status (CERTIFIED / BLOCKED, plus any skipped
  gates) before finalizing any task.

## Branch and merge discipline

- Use feature branches and pull requests for all non-emergency changes.
- Never push directly to `main` — the active repository ruleset rejects
  direct pushes; the PR path is the only path. Emergency recovery requires
  deliberately editing the ruleset first.
- A PR is mergeable only when both the local gate and the
  `verify-architecture-invariants` status check are green. GitHub enforces
  this via an active ruleset on `main` with no bypass actors (verified by
  red-gate test — see `.moe/README.md` §8); local verification remains
  mandatory as the first line of defense.
