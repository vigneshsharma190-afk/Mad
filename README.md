# Mad — MOE Enterprise Orchestration Scaffold

Multi-agent orchestration framework with local and remote verification gates.

- Framework documentation: [`.moe/README.md`](.moe/README.md)
- Agent profiles: [`.moe/profiles/`](.moe/profiles/)
- Local verification gate: `./bin/moe-verify.sh`
- Remote merge gate: [`.github/workflows/enterprise-agent-gate.yml`](.github/workflows/enterprise-agent-gate.yml)

## Current Enforcement State

**Verified working:** the `Enterprise Multi-Agent Integrity Gate` workflow runs
successfully on every pull request into `main`, `master`, or `release/*`. The
exact status check name it reports on PRs is **`verify-architecture-invariants`**
(first confirmed passing on [PR #1](https://github.com/vigneshsharma190-afk/Mad/pull/1)).

**Known limitation:** this repository is currently private, and GitHub branch
protection / ruleset enforcement on private repositories may require a paid or
team plan. Until that is in place, a failing `verify-architecture-invariants`
check is visible on the PR but does **not** technically block merging — the
merge button stays active.

### Mandatory workflow until remote enforcement is available

Every change must go through this manual gate discipline:

1. Create a feature branch.
2. Run `./bin/moe-verify.sh` locally.
3. Push the branch.
4. Open a PR into `main`.
5. Confirm the `verify-architecture-invariants` check passes on the PR.
6. Merge **only** after both the local gate and the PR check are green.

**Do not push directly to `main`** except for emergency recovery. Direct
pushes bypass the workflow entirely (it triggers on `pull_request` only), so a
direct push receives zero automated verification.
