#!/usr/bin/env bash
# Re-run the InReality c2pa_view validator evidence end-to-end.
#
# What it does, in order:
#   1. Refresh the C2PA + TSA trust list PEMs into
#      c2pa/evidence/validator/trust-list/anchors.pem (skipped with
#      --skip-trust-fetch; falls back to whatever is already on disk).
#   2. Regenerate c2pa/evidence/validator/conformance-samples/corpus.manifest.json
#      from the current samples directory (so the manifest tracks whatever
#      the operator has dropped in).
#   3. Run `flutter pub get && flutter analyze && flutter test` in
#      frontend/c2pa_view (skipped with --skip-flutter).
#   4. Run `c2pa/validate_evidence.sh` with C2PA_TRUST_ANCHORS_PEM pointed
#      at the cached PEM so the Rust integration test exercises the trust
#      validation path.
#   5. Mirror per-asset c2pa_view JSON outputs into
#      c2pa/evidence/validator/raw-json/<asset>.json so reviewers see one
#      JSON per corpus asset matching the asset filename.
#
# After this script completes, the only remaining manual step is to launch
# the testfiles_app, walk through the corpus, and capture per-asset PNG
# screenshots into c2pa/evidence/validator/screenshots/<asset>.png.
#
# Usage: bash frontend/c2pa_view/scripts/rerun-validation.sh
#        bash frontend/c2pa_view/scripts/rerun-validation.sh --skip-trust-fetch --skip-flutter

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
C2PA_VIEW_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$C2PA_VIEW_DIR/../.." && pwd)"

EVIDENCE_DIR="$REPO_ROOT/c2pa/evidence"
VALIDATOR_DIR="$EVIDENCE_DIR/validator"
SAMPLES_DIR="$VALIDATOR_DIR/conformance-samples"
TRUST_DIR="$VALIDATOR_DIR/trust-list"
TRUST_PEM="$TRUST_DIR/anchors.pem"
RAW_JSON_DIR="$VALIDATOR_DIR/raw-json"
UTILITY_DIR="$EVIDENCE_DIR/validator_utility"

SKIP_TRUST_FETCH=false
SKIP_FLUTTER=false
for arg in "$@"; do
    case "$arg" in
        --skip-trust-fetch) SKIP_TRUST_FETCH=true ;;
        --skip-flutter) SKIP_FLUTTER=true ;;
        -h|--help)
            sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *) echo "unknown arg: $arg" >&2; exit 2 ;;
    esac
done

BOLD='\033[1m'
NC='\033[0m'

step() { echo -e "\n${BOLD}== $1 ==${NC}"; }

# ============================================================
# 1. Refresh trust list PEMs
# ============================================================
step "1. Refreshing C2PA + TSA trust list PEMs"
mkdir -p "$TRUST_DIR"

# URLs mirror lib/core/trust/trust_list_service.dart constants.
CA_URL="https://raw.githubusercontent.com/c2pa-org/conformance-public/main/trust-list/C2PA-TRUST-LIST.pem"
TSA_URL="https://raw.githubusercontent.com/c2pa-org/conformance-public/main/trust-list/C2PA-TSA-TRUST-LIST.pem"

if $SKIP_TRUST_FETCH; then
    echo "  (skipped via --skip-trust-fetch)"
    if [ ! -f "$TRUST_PEM" ]; then
        echo "  WARN: $TRUST_PEM missing; downstream cargo test will run without trust list." >&2
    fi
elif command -v curl >/dev/null 2>&1; then
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    curl -fsSL "$CA_URL" -o "$tmp/ca.pem"
    curl -fsSL "$TSA_URL" -o "$tmp/tsa.pem"
    cat "$tmp/ca.pem" "$tmp/tsa.pem" > "$TRUST_PEM"
    echo "  Wrote $TRUST_PEM ($(wc -l < "$TRUST_PEM") lines)"
else
    echo "  WARN: curl not installed; cannot refresh trust list." >&2
    if [ ! -f "$TRUST_PEM" ]; then
        echo "  WARN: $TRUST_PEM does not exist either." >&2
    fi
fi

# ============================================================
# 2. Regenerate corpus.manifest.json
# ============================================================
step "2. Regenerating $SAMPLES_DIR/corpus.manifest.json"
"$SCRIPT_DIR/generate-corpus-manifest.py" "$SAMPLES_DIR"

# ============================================================
# 3. flutter pub get / analyze / test
# ============================================================
if $SKIP_FLUTTER; then
    step "3. Skipping flutter pub get / analyze / test (--skip-flutter)"
else
    step "3. Running flutter pub get / analyze / test"
    (cd "$C2PA_VIEW_DIR" && flutter pub get)
    (cd "$C2PA_VIEW_DIR" && flutter analyze)
    (cd "$C2PA_VIEW_DIR" && flutter test)
fi

# ============================================================
# 4. validate_evidence.sh (cargo test + c2patool)
# ============================================================
step "4. Running c2pa/validate_evidence.sh with trust list"
if [ -f "$TRUST_PEM" ]; then
    export C2PA_TRUST_ANCHORS_PEM="$TRUST_PEM"
    echo "  C2PA_TRUST_ANCHORS_PEM=$C2PA_TRUST_ANCHORS_PEM"
else
    echo "  (no PEM available; running with default trust)"
    unset C2PA_TRUST_ANCHORS_PEM || true
fi
bash "$REPO_ROOT/c2pa/validate_evidence.sh" "$EVIDENCE_DIR"

# ============================================================
# 5. Mirror c2pa_view per-asset JSON into raw-json/<asset>.json
# ============================================================
step "5. Mirroring c2pa_view JSON outputs into raw-json/"
mkdir -p "$RAW_JSON_DIR"
rm -f "$RAW_JSON_DIR"/*.json
"$SCRIPT_DIR/mirror-validator-json.py" \
    "$UTILITY_DIR" \
    "$SAMPLES_DIR" \
    "$RAW_JSON_DIR"

# ============================================================
# Done
# ============================================================
step "Done"
cat <<EOF
Next step (operator): open the testfiles_app or example app, walk
through each corpus asset, and capture a PNG screenshot to
$VALIDATOR_DIR/screenshots/<asset>.png.

Naming: the screenshot filename must equal the asset filename with the
extension replaced by .png (e.g. yt_inspiration_thumbnail.jpg →
yt_inspiration_thumbnail.png).
EOF
