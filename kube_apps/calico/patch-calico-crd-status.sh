#!/usr/bin/env bash
# =============================================================================
# patch-calico-crd-status.sh
#
# Workaround for https://github.com/projectcalico/calico/pull/12352
#
# Adds subresources: {status: {}} and status OpenAPI schemas to the
# IPPool, Tier, and CalicoNodeStatus v1 CRDs so that calico-kube-controllers
# can write v3 objects (which include a status field) without the API server
# logging "Warning: unknown field \"status\"" every 10 seconds.
#
# Because the tigera-operator with -manage-crds=true embeds its own CRD
# templates and instantly reverts manual changes, this script also switches
# the operator to -manage-crds=false.
#
# REVERT: Once an upstream Calico release ships the PR fix, run this script
# with --revert to re-enable -manage-crds=true and remove the workaround.
#
# Usage:
#   ./patch-calico-crd-status.sh           # apply the workaround
#   ./patch-calico-crd-status.sh --check   # only check current state
#   ./patch-calico-crd-status.sh --revert  # re-enable operator CRD mgmt
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CRD_FILE="${SCRIPT_DIR}/v1_crd_projectcalico_org.yaml"
readonly OPERATOR_FILE="${SCRIPT_DIR}/tigera-operator.yaml"
readonly OPERATOR_NAMESPACE="tigera-operator"
readonly OPERATOR_DEPLOYMENT="tigera-operator"
readonly CALICO_NAMESPACE="calico-system"

readonly -a AFFECTED_CRDS=(
  "ippools.crd.projectcalico.org"
  "tiers.crd.projectcalico.org"
  "caliconodestatuses.crd.projectcalico.org"
)

# CRDs that need both subresource + schema (CalicoNodeStatus only needs subresource)
readonly -a CRDS_NEED_SCHEMA=(
  "ippools.crd.projectcalico.org"
  "tiers.crd.projectcalico.org"
)

# ---------------------------------------------------------------------------
# Colours
# ---------------------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ---------------------------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------------------------
check_prerequisites() {
  local missing=0
  for cmd in kubectl python3; do
    if ! command -v "$cmd" &>/dev/null; then
      error "Required command not found: $cmd"
      missing=1
    fi
  done
  python3 -c "import yaml" 2>/dev/null || { error "Python package 'pyyaml' is required (pip install pyyaml)"; missing=1; }
  [[ $missing -eq 0 ]] || { error "Aborting — prerequisites not met."; exit 1; }
  [[ -f "$CRD_FILE" ]]      || { error "Not found: $CRD_FILE";      exit 1; }
  [[ -f "$OPERATOR_FILE" ]] || { error "Not found: $OPERATOR_FILE"; exit 1; }
}

# ---------------------------------------------------------------------------
# State checks
# ---------------------------------------------------------------------------
crd_has_status_subresource() {
  # Returns 0 (true) if the live cluster CRD already has subresources.status
  local name="$1"
  local result
  result=$(kubectl get crd "$name" -o json 2>/dev/null \
    | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['spec']['versions'][0].get('subresources',{}).get('status','MISSING'))" 2>/dev/null)
  [[ "$result" != "MISSING" ]]
}

yaml_crd_has_status_subresource() {
  local name="$1"
  python3 - "$CRD_FILE" "$name" <<'PYEOF'
import sys, yaml
file, name = sys.argv[1], sys.argv[2]
with open(file) as f:
    docs = [d for d in yaml.safe_load_all(f.read()) if d]
for doc in docs:
    if doc.get('metadata', {}).get('name') == name:
        v = doc['spec']['versions'][0]
        sys.exit(0 if 'status' in v.get('subresources', {}) else 1)
sys.exit(1)
PYEOF
}

operator_manages_crds() {
  # Returns 0 (true) if live operator deployment still has -manage-crds=true
  kubectl get deployment "$OPERATOR_DEPLOYMENT" -n "$OPERATOR_NAMESPACE" \
    -o jsonpath='{.spec.template.spec.containers[0].args}' 2>/dev/null \
    | grep -q 'manage-crds=true'
}

# ---------------------------------------------------------------------------
# Check mode — report current state without changing anything
# ---------------------------------------------------------------------------
run_check() {
  info "=== Current state ==="
  local all_good=true

  for crd in "${AFFECTED_CRDS[@]}"; do
    if crd_has_status_subresource "$crd"; then
      success "Live CRD has status subresource: $crd"
    else
      warn    "Live CRD MISSING status subresource: $crd"
      all_good=false
    fi

    if yaml_crd_has_status_subresource "$crd"; then
      success "YAML has status subresource: $crd"
    else
      warn    "YAML MISSING status subresource: $crd"
      all_good=false
    fi
  done

  if operator_manages_crds; then
    warn "Operator is still managing CRDs (-manage-crds=true)"
    all_good=false
  else
    success "Operator is NOT managing CRDs (-manage-crds=false)"
  fi

  echo ""
  if [[ "$all_good" == true ]]; then
    success "Workaround is fully applied — no action needed."
    return 0
  else
    warn "Workaround is NOT fully applied — run without --check to fix."
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Patch YAML files
# ---------------------------------------------------------------------------
patch_yaml_files() {
  info "Patching YAML: adding status subresource + schema to affected CRDs..."

  python3 - "$CRD_FILE" "${CRDS_NEED_SCHEMA[*]}" <<'PYEOF'
import sys, yaml

crd_file = sys.argv[1]
schema_targets = set(sys.argv[2].split())

# metav1.Condition-like status schema (matches upstream PR shape)
STATUS_SCHEMA = {
    'description': 'Status of the resource.',
    'properties': {
        'conditions': {
            'description': 'Conditions represents the latest observed set of conditions for this component.',
            'items': {
                'description': 'Condition contains details for one aspect of the current state of this API Resource.',
                'properties': {
                    'lastTransitionTime': {
                        'description': 'lastTransitionTime is the last time the condition transitioned from one status to another.',
                        'format': 'date-time',
                        'type': 'string',
                    },
                    'message': {
                        'description': 'message is a human readable message indicating details about the transition.',
                        'maxLength': 32768,
                        'type': 'string',
                    },
                    'observedGeneration': {
                        'description': 'observedGeneration represents the .metadata.generation that the condition was set based upon.',
                        'format': 'int64',
                        'minimum': 0,
                        'type': 'integer',
                    },
                    'reason': {
                        'description': "reason contains a programmatic identifier indicating the reason for the condition's last transition.",
                        'maxLength': 1024,
                        'minLength': 1,
                        'pattern': r'^[A-Za-z]([A-Za-z0-9_,:]*[A-Za-z0-9_])?$',
                        'type': 'string',
                    },
                    'status': {
                        'description': 'status of the condition, one of True, False, Unknown.',
                        'enum': ['True', 'False', 'Unknown'],
                        'type': 'string',
                    },
                    'type': {
                        'description': 'type of condition in CamelCase.',
                        'maxLength': 316,
                        'pattern': r'^([a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*/)?(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])$',
                        'type': 'string',
                    },
                },
                'required': ['lastTransitionTime', 'message', 'reason', 'status', 'type'],
                'type': 'object',
            },
            'type': 'array',
            'x-kubernetes-list-map-keys': ['type'],
            'x-kubernetes-list-type': 'map',
        }
    },
    'type': 'object',
}

SUBRESOURCE_STATUS = {'status': {}}
ALL_TARGETS = {
    'ippools.crd.projectcalico.org',
    'tiers.crd.projectcalico.org',
    'caliconodestatuses.crd.projectcalico.org',
}

with open(crd_file) as f:
    docs = list(yaml.safe_load_all(f.read()))

changed = []
for doc in docs:
    if not doc:
        continue
    name = doc.get('metadata', {}).get('name', '')
    if name not in ALL_TARGETS:
        continue
    for version in doc['spec']['versions']:
        # Add subresources.status if missing
        if 'status' not in version.get('subresources', {}):
            version.setdefault('subresources', {})['status'] = {}
            changed.append(f"  {name}: added subresources.status")
        # Add status schema for IPPool and Tier
        if name in schema_targets:
            props = version['schema']['openAPIV3Schema']['properties']
            if 'status' not in props:
                props['status'] = STATUS_SCHEMA
                changed.append(f"  {name}: added status OpenAPI schema")

for msg in changed:
    print(msg)
if not changed:
    print("  No changes needed in YAML — already patched.")

with open(crd_file, 'w') as f:
    yaml.dump_all(docs, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
PYEOF

  success "YAML CRD file patched."
}

patch_operator_yaml() {
  info "Patching YAML: setting -manage-crds=false in tigera-operator.yaml..."

  if grep -q '\-manage-crds=false' "$OPERATOR_FILE"; then
    success "Operator YAML already has -manage-crds=false — skipping."
    return 0
  fi

  sed -i.bak \
    's/- -manage-crds=true/- -manage-crds=false/' \
    "$OPERATOR_FILE"

  # Add or update the comment block above the flag
  python3 - "$OPERATOR_FILE" <<'PYEOF'
import sys, re

file = sys.argv[1]
with open(file) as f:
    content = f.read()

old = '            - -manage-crds=false'
new = (
    '            # CRDs managed manually via v1_crd_projectcalico_org.yaml.\n'
    '            # See: https://github.com/projectcalico/calico/pull/12352\n'
    '            # Revert to -manage-crds=true once Calico ships the fix.\n'
    '            - -manage-crds=false'
)

# Only add the comment if it's not already there
if '# CRDs managed manually' not in content:
    content = content.replace(old, new, 1)
    with open(file, 'w') as f:
        f.write(content)
    print("  Comment block added above -manage-crds=false.")
else:
    print("  Comment block already present — skipping.")
PYEOF

  rm -f "${OPERATOR_FILE}.bak"
  success "Operator YAML patched."
}

# ---------------------------------------------------------------------------
# Apply to live cluster
# ---------------------------------------------------------------------------
apply_crds_to_cluster() {
  info "Applying patched CRDs to cluster..."

  python3 - "$CRD_FILE" <<'PYEOF'
import sys, yaml, subprocess, tempfile, os

crd_file = sys.argv[1]
targets = {
    'ippools.crd.projectcalico.org',
    'tiers.crd.projectcalico.org',
    'caliconodestatuses.crd.projectcalico.org',
}

with open(crd_file) as f:
    docs = list(yaml.safe_load_all(f.read()))

for doc in docs:
    if not doc:
        continue
    name = doc.get('metadata', {}).get('name', '')
    if name not in targets:
        continue

    tmp = tempfile.NamedTemporaryFile(mode='w', suffix='.yaml', delete=False)
    yaml.dump(doc, tmp, default_flow_style=False)
    tmp.close()

    r = subprocess.run(['kubectl', 'replace', '-f', tmp.name], capture_output=True, text=True)
    if r.returncode != 0:
        r = subprocess.run(
            ['kubectl', 'apply', '--server-side', '--force-conflicts', '-f', tmp.name],
            capture_output=True, text=True,
        )
    os.unlink(tmp.name)
    print("  " + (r.stdout + r.stderr).strip())
PYEOF

  success "CRDs applied."
}

patch_operator_in_cluster() {
  if ! operator_manages_crds; then
    success "Live operator already has -manage-crds=false — skipping."
    return 0
  fi

  info "Patching live tigera-operator deployment to -manage-crds=false..."
  kubectl patch deployment "$OPERATOR_DEPLOYMENT" -n "$OPERATOR_NAMESPACE" \
    --type='json' \
    -p='[{"op":"replace","path":"/spec/template/spec/containers/0/args/0","value":"-manage-crds=false"}]'

  info "Waiting for operator rollout..."
  kubectl rollout status deployment/"$OPERATOR_DEPLOYMENT" \
    -n "$OPERATOR_NAMESPACE" --timeout=90s

  success "Live operator patched."
}

verify() {
  info "Verifying..."
  local issues=0

  for crd in "${AFFECTED_CRDS[@]}"; do
    if crd_has_status_subresource "$crd"; then
      success "Live CRD subresources.status present: $crd"
    else
      error "Live CRD still missing subresources.status: $crd"
      issues=$((issues + 1))
    fi
  done

  if operator_manages_crds; then
    error "Operator is still managing CRDs — patch may not have applied."
    issues=$((issues + 1))
  else
    success "Operator is not managing CRDs (-manage-crds=false)"
  fi

  echo ""
  if [[ $issues -eq 0 ]]; then
    success "All checks passed — warnings should be gone."
    info "Monitor with: kubectl logs -n ${CALICO_NAMESPACE} -l k8s-app=calico-kube-controllers --since=30s"
  else
    error "$issues issue(s) remain — review errors above."
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Revert: re-enable operator CRD management
# ---------------------------------------------------------------------------
run_revert() {
  info "=== Reverting workaround (re-enabling -manage-crds=true) ==="
  warn "Only do this if the upstream Calico release includes PR #12352!"
  echo ""

  # Update YAML file
  if grep -q '\-manage-crds=true' "$OPERATOR_FILE"; then
    info "Operator YAML already has -manage-crds=true."
  else
    sed -i.bak 's/- -manage-crds=false/- -manage-crds=true/' "$OPERATOR_FILE"
    # Remove the workaround comment lines
    python3 - "$OPERATOR_FILE" <<'PYEOF'
import sys, re
file = sys.argv[1]
with open(file) as f:
    content = f.read()
lines = content.splitlines(keepends=True)
cleaned = [l for l in lines if '# CRDs managed manually' not in l
                             and '# See: https://github.com/projectcalico/calico/pull/12352' not in l
                             and '# Revert to -manage-crds=true' not in l]
with open(file, 'w') as f:
    f.writelines(cleaned)
print("  Removed workaround comments from operator YAML.")
PYEOF
    rm -f "${OPERATOR_FILE}.bak"
    success "Operator YAML reverted to -manage-crds=true."
  fi

  # Patch live deployment
  if operator_manages_crds; then
    success "Live operator already has -manage-crds=true."
  else
    info "Patching live operator to -manage-crds=true..."
    kubectl patch deployment "$OPERATOR_DEPLOYMENT" -n "$OPERATOR_NAMESPACE" \
      --type='json' \
      -p='[{"op":"replace","path":"/spec/template/spec/containers/0/args/0","value":"-manage-crds=true"}]'
    kubectl rollout status deployment/"$OPERATOR_DEPLOYMENT" \
      -n "$OPERATOR_NAMESPACE" --timeout=90s
    success "Live operator reverted."
  fi

  success "Revert complete. The operator will now manage CRDs automatically."
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  local mode="apply"
  [[ "${1:-}" == "--check"  ]] && mode="check"
  [[ "${1:-}" == "--revert" ]] && mode="revert"

  echo ""
  echo "========================================================"
  echo " Calico CRD status-subresource patch"
  echo " Workaround: github.com/projectcalico/calico/pull/12352"
  echo " Mode: $mode"
  echo "========================================================"
  echo ""

  check_prerequisites

  case "$mode" in
    check)  run_check ;;
    revert) run_revert ;;
    apply)
      run_check && { success "Already fully applied — nothing to do."; exit 0; } || true
      echo ""
      info "=== Applying workaround ==="
      patch_yaml_files
      patch_operator_yaml
      patch_operator_in_cluster
      apply_crds_to_cluster
      echo ""
      verify
      ;;
  esac
}

main "$@"

