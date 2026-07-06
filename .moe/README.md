# MOE — Enterprise Master Orchestrator Engine

A stack-agnostic, autonomous multi-agent orchestration framework engineered for
high-production-level deliverables. MOE coordinates six specialized sub-agents
through deterministic workflows, enforces immutable engineering invariants, and
ships with local + remote verification gates that block unsafe code, schema,
security, and compliance changes before they reach an integration branch.

---

## 1. Core Mission

MOE is a production-grade enterprise orchestration system that can:

1. **Spin up specialized autonomous sub-agents** — six role-bounded agents, each
   with an explicit objective, system prompt, data inputs, operational
   boundaries, and known failure modes (see [`profiles/`](profiles/)).
2. **Coordinate agents through deterministic workflows** — a single state
   machine (§5) governs every task from objective parsing to branch
   finalization; there are no ad-hoc paths.
3. **Enforce strict software engineering boundaries** — each agent's write
   authority is scoped; cross-boundary actions require approval tokens from the
   owning agent.
4. **Prevent unsafe code, schema, security, compliance, or architectural
   changes** — via consensus gatekeeping, hard-rule vetoes, and the local
   (`bin/moe-verify.sh`) and remote
   (`.github/workflows/enterprise-agent-gate.yml`) enforcement engines.
5. **Extract reusable skills from its own workflows** — the five Skill Cards in
   §4 are distilled, executable reasoning sequences.
6. **Output reusable operational patterns** — everything in this directory is
   repository-agnostic and can be dropped into any enterprise codebase.

---

## 2. Architecture Overview

```
                        ┌─────────────────────────────┐
                        │  MASTER ORCHESTRATOR ENGINE │
                        └──────────────┬──────────────┘
                                       │
        ┌──────────────┬───────────────┼───────────────┬──────────────┐
        ▼              ▼               ▼               ▼              ▼
 ┌────────────┐ ┌────────────┐ ┌─────────────┐ ┌─────────────┐ ┌────────────┐
 │  Planning  │ │   Coding   │ │  Reviewing  │ │ Maintaining │ │ Compliance │
 │   Agent    │ │   Agent    │ │    Agent    │ │    Agent    │ │ & Security │
 └────────────┘ └────────────┘ └─────────────┘ └─────────────┘ └────────────┘
        └──────────────┴───────────────┬───────────────┴──────────────┘
                                       ▼
                        ┌─────────────────────────────┐
                        │ Structural Integrity Agent  │
                        │   (absolute pipeline veto)  │
                        └─────────────────────────────┘
```

| Agent | Role | Profile | Write authority | Veto power |
|---|---|---|---|---|
| Planning Agent | Systemic Architect & TPM | [profiles/planning-agent.md](profiles/planning-agent.md) | Backlogs / tickets only | No |
| Coding Agent | Defensive Core Engineer | [profiles/coding-agent.md](profiles/coding-agent.md) | Feature branches only | No |
| Reviewing Agent | Hyper-Critical Automated Auditor | [profiles/reviewing-agent.md](profiles/reviewing-agent.md) | Approval/rejection tokens only | Merge veto |
| Maintaining Agent | SRE & Database Lifecycle Guardian | [profiles/maintaining-agent.md](profiles/maintaining-agent.md) | Migrations, debt ledger | Schema-lock veto |
| Structural Integrity Agent | Hard-Rule Guardrail Gatekeeper | [profiles/structural-integrity-agent.md](profiles/structural-integrity-agent.md) | Failure tokens only | Absolute, un-bypassable |
| Data Compliance & Security Agent | SOC2/GDPR Compliance Auditor | [profiles/compliance-security-agent.md](profiles/compliance-security-agent.md) | Binary compliance reports only | Build-block veto |

Each profile sheet is a self-contained context overlay: load it verbatim as a
sub-agent's system context and the agent inherits its objective, prompt,
inputs, boundaries, and failure-mode watchlist.

---

## 3. Core Invariant Rules

These invariants are absolute. Any violation halts the pipeline with an
un-bypassable failure token. There are no exceptions and no override flags.

1. **No untyped or implicit `any` states.** Every value crossing a module
   boundary carries an explicit, verifiable type.
2. **No hardcoded secrets, credentials, or live API keys** — anywhere in
   tracked source, configuration templates, or diffs.
3. **No database schema changes without matching migration files.** Schema
   declarations and migrations move in lockstep, in the same change set.
4. **No new database entities without explicit Row Level Security migration
   commands** (`ENABLE ROW LEVEL SECURITY` + `CREATE POLICY` for SELECT,
   INSERT, UPDATE, and DELETE), defined in version-controlled migration
   scripts — never in application runtime files.
5. **No unsafe destructive migration operations** (`DROP COLUMN`,
   `DROP TABLE`, `SET NOT NULL` without default, blocking renames) without
   expand-and-contract migration safety across separate deploy steps.
6. **No unmasked PII inside logs, stdout, debug traces, or data intake
   routes.** Names, emails, billing tokens, and identifiers are masked, hashed,
   or anonymized before reaching any sink.
7. **No multi-tenant authorization bypasses.** Tenant isolation and financial
   authorization gates execute in memory before any operational data entry;
   override flags such as `bypassBillingVerification = true` are forbidden.
8. **No production merge without successful local and remote verification
   gates** — `bin/moe-verify.sh` locally, the Enterprise Multi-Agent Integrity
   Gate remotely, and consensus tokens from all gatekeeping agents.

---

## 4. Reusable Skill Cards

Skills are extracted, deterministic reasoning sequences. Each returns a binary
validation result: `1` (pass, continue) or `0` (fail, halt/route). They are
implemented locally in [`../bin/moe-verify.sh`](../bin/moe-verify.sh) and
remotely in the CI gate.

---

### SKILL-001 — CONTEXT-PRUNING

**Trigger Condition:**
Initialization of any code modification or analysis task inside the repository
workspace.

**Step-by-Step Execution Protocol:**

1. Parse the targeted file nodes declared by the Planning Agent ticket
   definition.
2. Traverse the Abstract Syntax Tree to trace direct imports, parameter
   models, and explicit parent types.
3. Construct a localized text map containing exclusively the target code file,
   related interface schemas, and core database models.
4. Strip away all unrelated directory paths and peripheral code units to
   compress the sub-agent's prompt layout.

**Validation Check:**
Return `1` if the context bundle stays strictly bounded to immediate
dependency nodes. Return `0` and halt orchestration if unrelated repository
paths bleed into the active prompt frame.

---

### SKILL-002 — AST-COMPILATION-VERIFIER

**Trigger Condition:**
Coding Agent reports a successful file adjustment cycle.

**Step-by-Step Execution Protocol:**

1. Capture all changed file tracks within the isolated workspace environment.
2. Invoke a local workspace AST type check on downstream consumer modules.
3. Validate all adjusted module export signatures against existing global
   integration models.
4. Process a line-by-line lint check on updated files to confirm zero style or
   runtime standard deviations.

**Validation Check:**
Return `1` if all modified modules resolve without structural compilation
errors or implicit type mutations. Return `0` and route output logs directly
to the Autonomous Self-Correction loop (§6.1).

---

### SKILL-003 — ENTROPY-CREDENTIAL-SHIELD

**Trigger Condition:**
Modification or generation of any environment variables, configuration tracks,
or application endpoints.

**Step-by-Step Execution Protocol:**

1. Scan all uncommitted lines using high-entropy regex arrays tuned for
   platform credentials, cryptographic keys, and connection strings.
2. Parse local ignore manifests such as `.gitignore` to verify environment
   parameters and local secrets remain locked out of tracking.
3. Inspect active configuration templates such as `.env.example` to ensure
   only non-functional mocked values exist.
4. Intercept the outbound data stream to confirm zero hardcoded credentials
   reside within production endpoints.

**Validation Check:**
Return `1` if all checked source lines contain absolutely zero high-entropy
keys or live credentials. Return `0`, force a local change wipe, and
immediately lock down multi-agent operations if an indicator is found.

---

### SKILL-004 — RLS-SANITY

**Trigger Condition:**
Introduction of a new database entity or modification to `schema.prisma`.

**Step-by-Step Execution Protocol:**

1. Parse the git diff for any lines matching `model [Name]`.
2. Locate the corresponding generated `.sql` migration file inside
   `prisma/migrations/`.
3. Scan the `.sql` file for the exact string:
   `ALTER TABLE "Name" ENABLE ROW LEVEL SECURITY;`.
4. Verify the existence of `CREATE POLICY` statements covering `SELECT`,
   `INSERT`, `UPDATE`, and `DELETE` actions.

**Validation Check:**
Return `1` if RLS strings exist inside the migration file. Return `0` and halt
the pipeline if RLS commands are missing or written inside application runtime
files.

---

### SKILL-005 — PII-LEAK-INTERCEPTION

**Trigger Condition:**
Code modifications applied to data intake routers, application trace
configurations, or data storage sinks.

**Step-by-Step Execution Protocol:**

1. Audit data mapping logic across changed files to check for fields
   representing names, emails, billing tokens, or identification elements.
2. Track the execution lifecycle of those identified data fields to confirm
   they are masked or hashed before stdout or file-logging sink outputs.
3. Inspect transport-layer endpoints to ensure all personal data is forced
   through TLS/HTTPS encrypted configurations.
4. Verify that data mutation paths pass securely through anonymization
   utilities before reaching non-production storage targets.

**Validation Check:**
Return `1` if the audited data paths enforce explicit encryption, masking, and
privacy-preservation laws. Return `0` and halt the compilation loop if an
unmasked PII leak risk is caught.

---

## 5. Deterministic Orchestration State Machine

When acting as the Master Orchestrator inside a repository, follow this state
machine exactly. No state may be skipped; no transition may be improvised.

```text
[System Ready]
      |
      v
(Parse High-Level Objective)
      |
      v
[Invoke Planning Agent]
      |
      v
[Isolate Code Context]          <- SKILL-001-CONTEXT-PRUNING
      |
      v
[Apply Target Code Edits]       <- Coding Agent, localized edits only
      |
      v
[Invoke Review Engine]          <- SKILL-002 + Reviewing Agent
      |
      +--> [Validation Fails]
      |          |
      |          v
      |   [Self-Correction Loop]
      |          |
      |          v
      |   [Max 2 Passes Reached?]
      |          |
      |          +--> Yes --> [Freeze & Halt]
      |          |
      |          +--> No --> [Apply Target Code Edits]
      |
      +--> [Validation Passes]
                 |
                 v
      [Invoke Compliance & Structural Integrity Agents]
                 |                <- SKILL-003, SKILL-004, SKILL-005
                 v
      [Consensus Verification]    <- all approval tokens required
                 |
                 +--> [Valid] --> [Finalize Output Branch]
                 |
                 +--> [Invalid] --> [Trigger Circuit Breaker]
```

---

## 6. Agentic Guardrails

### 6.1 Autonomous Self-Correction

- If code modifications fail automated code review, static compilation, or
  lint evaluation, the Coding Agent must ingest diagnostic error logs directly
  from the runtime buffer and attempt an autonomous correction patch.
- The pipeline limits automated correction passes to a **maximum of 2
  sequential attempts per task** before escalating to a human engineer through
  structural freeze routines.

### 6.2 Runaway Circuit Breakers

- Cap all multi-agent recursive logic and multi-file editing workflows at a
  **maximum of 3 loops per task**.
- If a task cannot be verified as 100% stable, fully compiled, and compliant
  within 3 loops, freeze execution.
- Output an operational state log dump to `.moe/circuit_breaker.json`.
- Halt until human intervention occurs.

### 6.3 Consensus-Based Gatekeeping

- Branch integration requires absolute, independent authorization tokens from
  **both** the Reviewing Agent and the Structural Integrity Agent, plus a
  clean compliance status from the Data Compliance & Security Agent.
- Zero exceptions for omitted unit testing.
- Zero exceptions for missing Row Level Security configurations.
- Zero exceptions for unhandled type assignments within source files.

### 6.4 Resource Conservation

- Limit sub-agent visibility strictly to minimal context blocks: the target
  file, immediate import objects, and relevant database entity parameters.
- Never parse or pass entire repository structures into a sub-agent's prompt
  workspace.
- Prefer targeted line selections and token-efficient AST sub-graphs over
  full-file dumps.

---

## 7. Enforcement Engines

| Layer | Artifact | Runs |
|---|---|---|
| Local | [`bin/moe-verify.sh`](../bin/moe-verify.sh) | On demand / pre-commit; mirrors Skill Cards 001–005 against the working git diff |
| Remote | [`.github/workflows/enterprise-agent-gate.yml`](../.github/workflows/enterprise-agent-gate.yml) | On every pull request into `main`, `master`, or `release/*`; merge-blocking |

Run the local gate before every commit:

```sh
./bin/moe-verify.sh          # audit the working diff (fast pre-commit check)
./bin/moe-verify.sh --full   # audit every tracked + untracked file in the repo
```

Diff mode is the pre-commit gate. Full mode sweeps the entire repository
against the same skill-card gates — use it when adopting MOE in an existing
codebase, after large merges, or as a periodic compliance audit.

A merge is legal only when **both** engines return green and all consensus
tokens (§6.3) are present.

---

## 8. Current Enforcement State

**Remote enforcement is ACTIVE and merge-blocking.** A repository ruleset
named `main` (enforcement: active, zero bypass actors) targets the `main`
branch and requires the **`verify-architecture-invariants`** status check to
pass before any merge. A failing MOE gate does not merely mark the PR red —
GitHub physically disables the merge for everyone, including repository
admins.

The active ruleset enforces:

- Pull request required before merging (direct pushes to `main` are blocked)
- Required status check: `verify-architecture-invariants`, with the strict
  up-to-date policy (the gate re-runs against the true merge result)
- Linear history required
- No force pushes, no branch deletion
- No bypass actors — there is no admin escape hatch

**Proven by red-gate test:** enforcement was verified end-to-end with a
deliberate violation
([PR #7](https://github.com/vigneshsharma190-afk/Mad/pull/7)). A throwaway
branch introduced a Gate 5 authorization-bypass pattern; the
`verify-architecture-invariants` check failed and GitHub reported the PR as
`mergeStateStatus: BLOCKED`. The test PR was closed without merging and the
branch deleted. The local gate caught the same violation pre-commit, so both
enforcement layers fired on the same input.

### Required status check reference

**Exact check name:** `verify-architecture-invariants`

This is the job ID in `.github/workflows/enterprise-agent-gate.yml`; the job
has no display-name override, so GitHub registers the check run under the job
ID (confirmed via the check-runs API). If the ruleset is ever recreated, use
this name — not the workflow name (`Enterprise Multi-Agent Integrity Gate`);
required checks match on the job-level check-run name.

**Re-verifying enforcement** (after any ruleset change): open a throwaway
branch, add a line matching one of Gate 5's forbidden patterns — e.g. assign
the value `true` to the `bypassBillingVerification` flag in a source file —
push, and open a PR. The check must fail **and** the merge button must be
disabled. Close the PR and delete the branch without merging. If the button
stays active, the check name in the ruleset does not match
`verify-architecture-invariants` exactly.

(The forbidden string is deliberately not written out verbatim here: the CI
gate scans the entire PR diff including documentation, and quoting it
literally fails Gate 5 — which is itself a useful demonstration that the gate
works.)

### Standard change workflow

Remote enforcement does not replace local discipline — it is the backstop,
not the first line. Every change still follows this workflow:

1. Create a feature branch.
2. Run `./bin/moe-verify.sh` locally — mandatory before every commit.
3. Push the branch.
4. Open a PR into `main`.
5. Confirm the `verify-architecture-invariants` check passes on the PR.
6. Merge only after both the local gate and the PR check are green.

Direct pushes to `main` are now rejected by the ruleset, so the PR path is
the only path. Emergency recovery requires deliberately editing the ruleset
first — an intentionally heavy step.
