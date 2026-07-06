#!/usr/bin/env bash
#
# moe-verify.sh — MOE local verification gate.
#
# Local mirror of the MOE Reusable Skill Cards (.moe/README.md §4).
# Audits changes against the core invariant rules. Exit code 0 = all gates
# passed, 1 = one or more gates failed, 2 = environment cannot be verified
# (not a git repo / no commits / bad arguments).
#
# Modes:
#   diff (default)  audit the working diff (staged + unstaged vs base ref)
#                   plus untracked files — fast pre-commit check
#   --full          audit every tracked + untracked file in the repository —
#                   whole-repo compliance sweep (e.g. after adopting MOE in an
#                   existing codebase, or as a periodic invariant audit)
#
# Usage:
#   ./bin/moe-verify.sh                     # diff mode vs HEAD
#   MOE_BASE_REF=main ./bin/moe-verify.sh   # diff mode vs a base ref
#   ./bin/moe-verify.sh --full              # full-repository audit
#
set -euo pipefail

MODE="diff"
for arg in "$@"; do
  case "$arg" in
    --full) MODE="full" ;;
    -h|--help)
      sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s (supported: --full, --help)\n' "$arg" >&2
      exit 2
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Setup & reporting
# ---------------------------------------------------------------------------

if [ -t 1 ]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BOLD=""; RESET=""
fi

FAILURES=0
declare -a GATE_NAMES=()
declare -a GATE_RESULTS=()   # 1 = pass, 0 = fail, S = skipped

pass() { GATE_NAMES+=("$1"); GATE_RESULTS+=("1"); printf '%s[PASS]%s %s\n' "$GREEN" "$RESET" "$1"; }
skip() { GATE_NAMES+=("$1"); GATE_RESULTS+=("S"); printf '%s[SKIP]%s %s — %s\n' "$YELLOW" "$RESET" "$1" "$2"; }
fail() {
  GATE_NAMES+=("$1"); GATE_RESULTS+=("0"); FAILURES=$((FAILURES + 1))
  printf '%s[FAIL]%s %s\n' "$RED" "$RESET" "$1"
  printf '%s\n' "$2" | sed 's/^/       /'
}

printf '%s=== MOE Local Verification Gate ===%s\n' "$BOLD" "$RESET"

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf '%s[HALT]%s This directory is not a git repository.\n' "$RED" "$RESET"
  printf 'MOE verification audits git diffs. Run "git init" and create an initial commit first.\n'
  exit 2
}
cd "$REPO_ROOT"

if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  printf '%s[HALT]%s Repository has no commits yet — there is no baseline to diff against.\n' "$RED" "$RESET"
  printf 'Create an initial commit, then re-run ./bin/moe-verify.sh.\n'
  exit 2
fi

BASE_REF="${MOE_BASE_REF:-HEAD}"
if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  printf '%s[HALT]%s Base ref "%s" does not resolve.\n' "$RED" "$RESET" "$BASE_REF"
  exit 2
fi

printf 'Repository : %s\n' "$REPO_ROOT"
if [ "$MODE" = "full" ]; then
  printf 'Mode       : FULL repository audit (all tracked + untracked files)\n\n'
else
  printf 'Mode       : diff vs %s\n\n' "$BASE_REF"
fi

# Full diff of tracked changes (staged + unstaged) plus untracked files.
diff_all() {
  git diff "$BASE_REF" --
  git ls-files --others --exclude-standard -z \
    | xargs -0 -I{} git diff --no-index /dev/null {} 2>/dev/null || true
}

# Only the added lines of the diff, prefixed "path:line-content".
added_lines() {
  diff_all | awk '
    /^\+\+\+ b\// { file = substr($0, 7); next }
    /^\+\+\+ /    { file = ""; next }
    /^\+[^+]/ || /^\+$/ { if (file != "") print file ":" substr($0, 2) }
  '
}

# Every line of every audited file, prefixed "path:line-content" (full mode).
all_lines() {
  { git ls-files; git ls-files --others --exclude-standard; } | sort -u \
    | while IFS= read -r f; do
        [ -f "$f" ] || continue
        grep -I -H '' "$f" 2>/dev/null || true
      done
}

if [ "$MODE" = "full" ]; then
  CHANGED_FILES=$( { git ls-files; git ls-files --others --exclude-standard; } | sort -u )
  ADDED=$(all_lines)
  if [ -z "$CHANGED_FILES" ]; then
    printf '%s[INFO]%s Repository contains no files — nothing to verify.\n' "$YELLOW" "$RESET"
    exit 0
  fi
else
  CHANGED_FILES=$( { git diff --name-only "$BASE_REF" --; git ls-files --others --exclude-standard; } | sort -u )
  ADDED=$(added_lines)
  if [ -z "$CHANGED_FILES" ]; then
    printf '%s[INFO]%s No changes detected vs %s — nothing to verify.\n' "$YELLOW" "$RESET" "$BASE_REF"
    exit 0
  fi
fi

# The enforcement engines define the very signatures they hunt, so their own
# lines must not be pattern-scanned (they would self-match). Documentation
# (.md) quotes forbidden patterns descriptively and is not executable, so it
# is excluded from the code-execution gates (5, 5b, 6) but NOT from the
# secret scan — a real credential pasted into a doc is still a leak.
ENFORCEMENT_SELF='^(bin/moe-verify\.sh|\.github/workflows/enterprise-agent-gate\.yml):'
CODE_LINES=$(printf '%s\n' "$ADDED" | grep -v -E "$ENFORCEMENT_SELF" || true)
EXEC_LINES=$(printf '%s\n' "$CODE_LINES" | grep -v -E '^[^:]*\.(md|markdown|txt):' || true)

# ---------------------------------------------------------------------------
# GATE 1 — SKILL-002 AST-COMPILATION-VERIFIER (implicit-any + type surface)
# ---------------------------------------------------------------------------

GATE1="Gate 1: Implicit-any / type-safety scan (SKILL-002)"
TS_CHANGED=$(printf '%s\n' "$CHANGED_FILES" | grep -E '\.(ts|tsx|mts|cts)$' || true)
if [ -z "$TS_CHANGED" ]; then
  skip "$GATE1" "no TypeScript files in audit scope"
else
  ANY_HITS=$(printf '%s\n' "$ADDED" \
    | grep -E '\.(ts|tsx|mts|cts):' \
    | grep -E '(:\s*any\b|\bas\s+any\b|<any>|\bany\[\]|@ts-ignore|@ts-nocheck)' \
    | grep -v -E '(//.*moe:allow-any|\* )' || true)
  if [ -n "$ANY_HITS" ]; then
    fail "$GATE1" "Untyped or implicit 'any' states introduced (invariant #1):
$ANY_HITS"
  else
    pass "$GATE1"
  fi
  if [ -f package.json ] && command -v npx >/dev/null 2>&1 \
     && node -e "process.exit(require('./package.json').devDependencies?.typescript || require('./package.json').dependencies?.typescript ? 0 : 1)" 2>/dev/null; then
    printf '       Running workspace type check (tsc --noEmit)...\n'
    if ! npx tsc --noEmit >/tmp/moe-tsc.log 2>&1; then
      fail "Gate 1b: Workspace compilation (tsc --noEmit)" "$(tail -n 20 /tmp/moe-tsc.log)"
    else
      pass "Gate 1b: Workspace compilation (tsc --noEmit)"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# GATE 2 — SKILL-003 ENTROPY-CREDENTIAL-SHIELD
# ---------------------------------------------------------------------------

GATE2="Gate 2: High-entropy credential shield (SKILL-003)"
SECRET_REGEX='(sk_live_[0-9a-zA-Z]{10,}|sk-ant-[0-9a-zA-Z_-]{10,}|AIzaSy[0-9A-Za-z_-]{20,}|xoxb-[0-9A-Za-z-]{10,}|xapp-[0-9A-Za-z-]{10,}|AKIA[0-9A-Z]{16}|ghp_[0-9A-Za-z]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|(postgres|postgresql|mysql|mongodb(\+srv)?|redis|amqp)://[^/[:space:]:@]+:[^@[:space:]]+@|DATABASE_URL=[^[:space:]]*://[^[:space:]]*:[^[:space:]]*@)'
SECRET_HITS=$(printf '%s\n' "$CODE_LINES" | grep -E "$SECRET_REGEX" || true)
if [ -n "$SECRET_HITS" ]; then
  fail "$GATE2" "Hardcoded secrets, credentials, or live API keys detected (invariant #2):
$SECRET_HITS
Remove these values, rotate the exposed credentials, and load them from an untracked environment source."
else
  pass "$GATE2"
fi

GATE2B="Gate 2b: Environment file tracking & template hygiene (SKILL-003)"
ENV_ISSUES=""
TRACKED_ENVS=$(git ls-files | grep -E '(^|/)\.env(\.local|\.development|\.production|\.staging)?$' || true)
if [ -n "$TRACKED_ENVS" ]; then
  ENV_ISSUES+="Environment files are tracked by git (must be ignored): ${TRACKED_ENVS}"$'\n'
fi
for envfile in .env .env.local; do
  if [ -f "$envfile" ] && ! git check-ignore -q "$envfile" 2>/dev/null && ! git ls-files --error-unmatch "$envfile" >/dev/null 2>&1; then
    ENV_ISSUES+="$envfile exists but is not covered by .gitignore."$'\n'
  fi
done
if [ -f .env.example ]; then
  LIVE_IN_TEMPLATE=$(grep -E "$SECRET_REGEX" .env.example || true)
  if [ -n "$LIVE_IN_TEMPLATE" ]; then
    ENV_ISSUES+=".env.example contains live-looking values (templates must hold mocked placeholders only):"$'\n'"$LIVE_IN_TEMPLATE"$'\n'
  fi
fi
if [ -n "$ENV_ISSUES" ]; then
  fail "$GATE2B" "$ENV_ISSUES"
else
  pass "$GATE2B"
fi

GATE2C="Gate 2c: Unsafe environment variable exposure (SKILL-003)"
ENV_EXPOSURE=$(printf '%s\n' "$EXEC_LINES" \
  | grep -E '(console\.(log|info|warn|error|debug)|logger\.[a-z]+|print\(|println!)\s*\(.*process\.env|NEXT_PUBLIC_[A-Z_]*(SECRET|KEY|TOKEN|PASSWORD)|VITE_[A-Z_]*(SECRET|KEY|TOKEN|PASSWORD)|REACT_APP_[A-Z_]*(SECRET|KEY|TOKEN|PASSWORD)' \
  | grep -v -E 'moe:allow-env' || true)
if [ -n "$ENV_EXPOSURE" ]; then
  fail "$GATE2C" "Environment values logged or exposed to client bundles:
$ENV_EXPOSURE"
else
  pass "$GATE2C"
fi

# ---------------------------------------------------------------------------
# GATE 3 — Migration lockstep + SKILL-005 zero-downtime sanity
# ---------------------------------------------------------------------------

GATE3="Gate 3: Schema/migration lockstep (invariant #3)"
SCHEMA_CHANGED=$(printf '%s\n' "$CHANGED_FILES" | grep -E '(^|/)schema\.prisma$' || true)
MIGRATIONS_CHANGED=$(printf '%s\n' "$CHANGED_FILES" | grep -E '(^|/)(prisma/)?migrations/.*\.sql$' || true)
if [ -z "$SCHEMA_CHANGED" ]; then
  skip "$GATE3" "no schema.prisma in audit scope"
elif [ -z "$MIGRATIONS_CHANGED" ]; then
  fail "$GATE3" "schema.prisma changed but no migration .sql files accompany it.
Generate the migration in the same change set (e.g. prisma migrate dev)."
else
  pass "$GATE3"
fi

GATE3B="Gate 3b: Zero-downtime migration sanity (expand-and-contract)"
if [ -z "$MIGRATIONS_CHANGED" ]; then
  skip "$GATE3B" "no migration files in audit scope"
else
  UNSAFE_SQL=$(printf '%s\n' "$ADDED" \
    | grep -E 'migrations/.*\.sql:' \
    | grep -E -i '(DROP COLUMN|DROP TABLE|ALTER TABLE .* ALTER COLUMN .* SET NOT NULL|RENAME TO)' \
    | grep -v -i -- '-- moe:expand-contract' || true)
  if [ -n "$UNSAFE_SQL" ]; then
    fail "$GATE3B" "Destructive migration operations without expand-and-contract safety (invariant #5):
$UNSAFE_SQL
Split the change: expand (additive migration + dual-write), backfill, then contract in a
later deploy. Deliberate contract steps must carry the '-- moe:expand-contract' marker."
  else
    pass "$GATE3B"
  fi
fi

# ---------------------------------------------------------------------------
# GATE 4 — SKILL-004 RLS-SANITY
# ---------------------------------------------------------------------------

GATE4="Gate 4: Row Level Security sanity (SKILL-004)"
if [ -z "$SCHEMA_CHANGED" ]; then
  skip "$GATE4" "no schema.prisma in audit scope"
else
  NEW_MODELS=$(printf '%s\n' "$ADDED" | grep -E 'schema\.prisma:model ' | sed -E 's/.*schema\.prisma:model +([A-Za-z0-9_]+).*/\1/' | sort -u || true)
  if [ -z "$NEW_MODELS" ]; then
    skip "$GATE4" "schema changed but no new models introduced"
  else
    RLS_ISSUES=""
    for entity in $NEW_MODELS; do
      MIGRATION_HITS=$(grep -rl -E "ALTER TABLE \"$entity\" ENABLE ROW LEVEL SECURITY;" prisma/migrations 2>/dev/null || true)
      if [ -z "$MIGRATION_HITS" ]; then
        RLS_ISSUES+="Model '$entity' has no 'ALTER TABLE \"$entity\" ENABLE ROW LEVEL SECURITY;' in prisma/migrations/ (invariant #4)."$'\n'
        continue
      fi
      for action in SELECT INSERT UPDATE DELETE; do
        if ! grep -r -q -i -E "CREATE POLICY .* ON \"?$entity\"?.* FOR $action" prisma/migrations 2>/dev/null; then
          RLS_ISSUES+="Model '$entity' lacks a CREATE POLICY covering $action."$'\n'
        fi
      done
    done
    RUNTIME_RLS=$(printf '%s\n' "$EXEC_LINES" | grep -v -E 'migrations/.*\.sql:' | grep -E 'ENABLE ROW LEVEL SECURITY|CREATE POLICY' || true)
    if [ -n "$RUNTIME_RLS" ]; then
      RLS_ISSUES+="RLS commands found inside application runtime files — they must live in version-controlled migration scripts:"$'\n'"$RUNTIME_RLS"$'\n'
    fi
    if [ -n "$RLS_ISSUES" ]; then
      fail "$GATE4" "$RLS_ISSUES"
    else
      pass "$GATE4"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# GATE 5 — SKILL-005 PII-LEAK-INTERCEPTION
# ---------------------------------------------------------------------------

GATE5="Gate 5: PII leak interception (SKILL-005)"
PII_FIELDS='(email|e_mail|ssn|social_security|phone(Number|_number)?|firstName|first_name|lastName|last_name|fullName|full_name|dateOfBirth|date_of_birth|creditCard|credit_card|cardNumber|card_number|billingToken|billing_token|passport|driverLicense|driver_license|taxId|tax_id)'
PII_HITS=$(printf '%s\n' "$EXEC_LINES" \
  | grep -E "(console\.(log|info|warn|error|debug)|logger\.(info|warn|error|debug|log|trace)|print\(|println!|logging\.[a-z]+)\s*\(.*${PII_FIELDS}" \
  | grep -v -E '(mask|hash|redact|anonymi[sz]e|obfuscat)' \
  | grep -v -E 'moe:allow-pii' || true)
if [ -n "$PII_HITS" ]; then
  fail "$GATE5" "Potential unmasked PII flowing into logging sinks (invariant #6):
$PII_HITS
Mask, hash, or redact these fields before any stdout/file/log output."
else
  pass "$GATE5"
fi

GATE5B="Gate 5b: Insecure transport for data paths (SKILL-005)"
HTTP_HITS=$(printf '%s\n' "$EXEC_LINES" \
  | grep -E '["'"'"']http://(?!localhost|127\.0\.0\.1|0\.0\.0\.0)' -P 2>/dev/null \
  || printf '%s\n' "$EXEC_LINES" | grep -E '["'"'"']http://' | grep -v -E 'localhost|127\.0\.0\.1|0\.0\.0\.0' || true)
if [ -n "$HTTP_HITS" ]; then
  fail "$GATE5B" "Non-TLS endpoints introduced — personal data transport must use HTTPS:
$HTTP_HITS"
else
  pass "$GATE5B"
fi

# ---------------------------------------------------------------------------
# GATE 6 — Multi-tenant authorization invariants (invariant #7)
# ---------------------------------------------------------------------------

GATE6="Gate 6: Multi-tenant authorization constraints (invariant #7)"
BYPASS_HITS=$(printf '%s\n' "$EXEC_LINES" \
  | grep -E '(bypassBillingVerification\s*=\s*true|bypassTenantIsolation\s*=\s*true|skipAuthCheck\s*=\s*true|SKIP_TENANT_ISOLATION\s*=\s*(true|1))' || true)
if [ -n "$BYPASS_HITS" ]; then
  fail "$GATE6" "Authorization bypass patterns detected:
$BYPASS_HITS"
else
  pass "$GATE6"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

printf '\n%s=== MOE Gate Summary ===%s\n' "$BOLD" "$RESET"
i=0
while [ $i -lt ${#GATE_NAMES[@]} ]; do
  case "${GATE_RESULTS[$i]}" in
    1) printf '  %s1%s  %s\n' "$GREEN" "$RESET" "${GATE_NAMES[$i]}" ;;
    0) printf '  %s0%s  %s\n' "$RED" "$RESET" "${GATE_NAMES[$i]}" ;;
    S) printf '  %s-%s  %s (skipped)\n' "$YELLOW" "$RESET" "${GATE_NAMES[$i]}" ;;
  esac
  i=$((i + 1))
done

if [ "$FAILURES" -gt 0 ]; then
  printf '\n%s[BLOCKED]%s %d gate(s) failed. Integration is forbidden until every gate returns 1.\n' "$RED" "$RESET" "$FAILURES"
  exit 1
fi
printf '\n%s[CERTIFIED]%s All local MOE invariants and skill-card gates passed.\n' "$GREEN" "$RESET"
exit 0
