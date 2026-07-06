# Mad — MOE Enterprise Orchestration Scaffold

Multi-agent orchestration framework with local and remote verification gates.

- Framework documentation: [`.moe/README.md`](.moe/README.md)
- Agent profiles: [`.moe/profiles/`](.moe/profiles/)
- Local verification gate: `./bin/moe-verify.sh`
- Remote merge gate: [`.github/workflows/enterprise-agent-gate.yml`](.github/workflows/enterprise-agent-gate.yml)

## Current Enforcement State

**Remote enforcement is ACTIVE and merge-blocking.** A repository ruleset
named `main` (enforcement: active, no bypass actors) targets the `main`
branch and requires the **`verify-architecture-invariants`** status check —
a failing MOE gate physically disables the merge for everyone, including
admins. Enforcement was proven end-to-end with a red-gate test
([PR #7](https://github.com/vigneshsharma190-afk/Mad/pull/7)): a deliberate
Gate 5 violation failed the check, GitHub reported the PR as `BLOCKED`, and
the test PR was closed without merging.

Full details: [`.moe/README.md`](.moe/README.md) §8.

### Standard change workflow

Local verification remains mandatory — the remote gate is the backstop, not
the first line:

1. Create a feature branch.
2. Run `./bin/moe-verify.sh` locally before every commit.
3. Push the branch.
4. Open a PR into `main`.
5. Confirm the `verify-architecture-invariants` check passes on the PR.
6. Merge only after both the local gate and the PR check are green.

Direct pushes to `main` are rejected by the ruleset, so the PR path is the
only path.
