#!/bin/bash
# =============================================================================
# Project NEXUS — macOS Build Host Health Check (ANU-408)
# =============================================================================
# Checks SSH reachability, disk usage, CPU load, memory pressure, and
# GitHub Actions runner status on the self-hosted macOS CI host.
#
# Usage:
#   # From a CI runner or local workstation (SSHes into the macOS host):
#   bash scripts/check-macos-host-health.sh
#
#   # Directly on the macOS host:
#   LOCAL_MODE=1 bash scripts/check-macos-host-health.sh
#
# Required env vars (CI):
#   MACOS_HOST          — user@ip for SSH (e.g. admin@192.168.1.100)
#   MACOS_SSH_KEY_PATH  — path to SSH private key
#
# Optional env vars (CI):
#   GH_TOKEN            — GitHub PAT for runner status check
#   GH_REPO             — owner/repo (e.g. org/nexus-v1)
#   RUNNER_NAME         — expected runner name (default: macos-builder)
#
# Exit codes:
#   0 = healthy
#   1 = at least one critical check failed
#   2 = SSH connection failure
# =============================================================================

set -u

# --- Config ---
MACOS_HOST="${MACOS_HOST:-}"
MACOS_SSH_KEY_PATH="${MACOS_SSH_KEY_PATH:-}"
SSH_TIMEOUT="${SSH_TIMEOUT:-10}"

DISK_WARN_PCT="${DISK_WARN_PCT:-85}"
DISK_CRIT_PCT="${DISK_CRIT_PCT:-95}"
CPU_CRIT_PCT="${CPU_CRIT_PCT:-90}"
MEM_WARN_PCT="${MEM_WARN_PCT:-85}"

GH_TOKEN="${GH_TOKEN:-}"
GH_REPO="${GH_REPO:-}"
RUNNER_NAME="${RUNNER_NAME:-macos-builder}"

# --- Output format ---
OUTPUT_JSON="${OUTPUT_JSON:-0}"
ISSUES=()
WARNINGS=()

# --- Colors (TTY only) ---
if [ -t 1 ] && [ "${OUTPUT_JSON}" != "1" ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; NC=''
fi

log_ok()   { echo -e "${GREEN}[PASS]${NC} $1"; }
log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; WARNINGS+=("$1"); }
log_err()  { echo -e "${RED}[FAIL]${NC} $1"; ISSUES+=("$1"); }

run_remote() {
    local cmd="$1"
    if [ "${LOCAL_MODE:-0}" = "1" ]; then
        bash -c "$cmd"
    else
        ssh -i "$MACOS_SSH_KEY_PATH" \
            -o ConnectTimeout="$SSH_TIMEOUT" \
            -o StrictHostKeyChecking=accept-new \
            -o BatchMode=yes \
            "$MACOS_HOST" "$cmd"
    fi
}

echo -e "${BOLD}Project NEXUS — macOS Build Host Health Check${NC}"
echo "Host: ${MACOS_HOST:-localhost (local mode)}"
echo "Thresholds: disk warn=${DISK_WARN_PCT}% crit=${DISK_CRIT_PCT}% | cpu crit=${CPU_CRIT_PCT}% | mem warn=${MEM_WARN_PCT}%"
echo "============================================================"

# ---------------------------------------------------------------
# 1. SSH Connectivity
# ---------------------------------------------------------------
echo ""
echo -e "${BOLD}1. SSH Connectivity${NC}"

if [ "${LOCAL_MODE:-0}" = "1" ]; then
    log_ok "Running in local mode — SSH check skipped"
else
    if [ -z "$MACOS_HOST" ] || [ -z "$MACOS_SSH_KEY_PATH" ]; then
        log_err "MACOS_HOST or MACOS_SSH_KEY_PATH not set"
        exit 2
    fi

    if run_remote "echo ok" > /dev/null 2>&1; then
        log_ok "SSH connection successful"
    else
        log_err "SSH connection FAILED — host unreachable"
        exit 2
    fi
fi

# ---------------------------------------------------------------
# 2. Disk Usage
# ---------------------------------------------------------------
echo ""
echo -e "${BOLD}2. Disk Usage${NC}"

DISK_RAW=$(run_remote "df -h / | tail -1") || {
    log_err "Could not collect disk stats"
    exit 2
}

DISK_PCT=$(echo "$DISK_RAW" | awk '{gsub(/%/,""); print $(NF-1)}')
DISK_AVAIL=$(echo "$DISK_RAW" | awk '{print $(NF-2)}')

printf "  Root filesystem: %s%% used (%s available)\n" "$DISK_PCT" "$DISK_AVAIL"

if [ "$DISK_PCT" -ge "$DISK_CRIT_PCT" ]; then
    log_err "Disk usage CRITICAL: ${DISK_PCT}% (threshold: ${DISK_CRIT_PCT}%)"
elif [ "$DISK_PCT" -ge "$DISK_WARN_PCT" ]; then
    log_warn "Disk usage WARNING: ${DISK_PCT}% (threshold: ${DISK_WARN_PCT}%)"
else
    log_ok "Disk usage healthy: ${DISK_PCT}%"
fi

# ---------------------------------------------------------------
# 3. CPU Load (5-minute average)
# ---------------------------------------------------------------
echo ""
echo -e "${BOLD}3. CPU Load${NC}"

CPU_INFO=$(run_remote "sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 1") || CPU_INFO="1"
NCPU=$(echo "$CPU_INFO" | tr -d '[:space:]')

LOAD_RAW=$(run_remote "sysctl -n vm.loadavg 2>/dev/null || cat /proc/loadavg 2>/dev/null || echo '0 0 0'")
LOAD_5MIN=$(echo "$LOAD_RAW" | awk '{
    for(i=1;i<=NF;i++) {
        if ($i ~ /^[0-9]+\./) { count++; if(count==2) {print $i; exit} }
    }
}')
LOAD_5MIN="${LOAD_5MIN:-0}"

LOAD_PCT=$(awk "BEGIN {printf \"%.0f\", ($LOAD_5MIN / $NCPU) * 100}")

printf "  CPUs: %s | 5-min load avg: %s | Load %%: %s%%\n" "$NCPU" "$LOAD_5MIN" "$LOAD_PCT"

if [ "$LOAD_PCT" -ge "$CPU_CRIT_PCT" ]; then
    log_err "CPU load CRITICAL: ${LOAD_PCT}% of capacity (threshold: ${CPU_CRIT_PCT}%)"
else
    log_ok "CPU load healthy: ${LOAD_PCT}%"
fi

# ---------------------------------------------------------------
# 4. Memory Pressure
# ---------------------------------------------------------------
echo ""
echo -e "${BOLD}4. Memory${NC}"

MEM_RAW=$(run_remote "
if command -v vm_stat >/dev/null 2>&1; then
    PAGE_SIZE=\$(sysctl -n hw.pagesize)
    TOTAL_PAGES=\$(sysctl -n hw.memsize)
    FREE_PAGES=\$(vm_stat | awk '/Pages free/ {gsub(/\\./, \"\"); print \$3}')
    INACTIVE=\$(vm_stat | awk '/Pages inactive/ {gsub(/\\./, \"\"); print \$3}')
    TOTAL_MB=\$(( TOTAL_PAGES / 1048576 ))
    FREE_MB=\$(( (FREE_PAGES + INACTIVE) * PAGE_SIZE / 1048576 ))
    USED_MB=\$(( TOTAL_MB - FREE_MB ))
    echo \"\${USED_MB}|\${TOTAL_MB}\"
elif [ -f /proc/meminfo ]; then
    TOTAL=\$(awk '/MemTotal/ {print int(\$2/1024)}' /proc/meminfo)
    AVAIL=\$(awk '/MemAvailable/ {print int(\$2/1024)}' /proc/meminfo)
    USED=\$(( TOTAL - AVAIL ))
    echo \"\${USED}|\${TOTAL}\"
else
    echo '0|1'
fi
") || MEM_RAW="0|1"

MEM_USED=$(echo "$MEM_RAW" | cut -d'|' -f1)
MEM_TOTAL=$(echo "$MEM_RAW" | cut -d'|' -f2)
MEM_PCT=$(( MEM_USED * 100 / MEM_TOTAL ))

printf "  Memory: %s MB / %s MB (%s%% used)\n" "$MEM_USED" "$MEM_TOTAL" "$MEM_PCT"

if [ "$MEM_PCT" -ge "$MEM_WARN_PCT" ]; then
    log_warn "Memory usage WARNING: ${MEM_PCT}% (threshold: ${MEM_WARN_PCT}%)"
else
    log_ok "Memory usage healthy: ${MEM_PCT}%"
fi

# ---------------------------------------------------------------
# 5. GitHub Actions Runner Status
# ---------------------------------------------------------------
echo ""
echo -e "${BOLD}5. GitHub Actions Runner${NC}"

if [ -n "$GH_TOKEN" ] && [ -n "$GH_REPO" ]; then
    RUNNERS_JSON=$(curl -sS --max-time 10 \
        -H "Authorization: Bearer $GH_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/${GH_REPO}/actions/runners" 2>/dev/null)

    RUNNER_STATUS=$(echo "$RUNNERS_JSON" | \
        python3 -c "
import sys, json
data = json.load(sys.stdin)
for r in data.get('runners', []):
    if r['name'] == '$RUNNER_NAME':
        print(r['status'])
        sys.exit(0)
print('not_found')
" 2>/dev/null || echo "api_error")

    case "$RUNNER_STATUS" in
        online)
            log_ok "Runner '${RUNNER_NAME}' is online"
            ;;
        offline)
            log_err "Runner '${RUNNER_NAME}' is OFFLINE"
            ;;
        not_found)
            log_err "Runner '${RUNNER_NAME}' not found in ${GH_REPO}"
            ;;
        *)
            log_warn "Could not determine runner status (API error or parse failure)"
            ;;
    esac
else
    RUNNER_PROC=$(run_remote "pgrep -f 'actions-runner|Runner.Listener' >/dev/null 2>&1 && echo running || echo stopped")
    if [ "$RUNNER_PROC" = "running" ]; then
        log_ok "Runner process detected (set GH_TOKEN + GH_REPO for API-level check)"
    else
        log_warn "Runner process not detected (set GH_TOKEN + GH_REPO for definitive check)"
    fi
fi

# ---------------------------------------------------------------
# Summary
# ---------------------------------------------------------------
echo ""
echo "============================================================"

TOTAL_ISSUES=${#ISSUES[@]}
TOTAL_WARNINGS=${#WARNINGS[@]}

if [ "${OUTPUT_JSON}" = "1" ]; then
    STATUS="healthy"
    [ "$TOTAL_WARNINGS" -gt 0 ] && STATUS="degraded"
    [ "$TOTAL_ISSUES" -gt 0 ] && STATUS="unhealthy"

    ISSUES_JSON="[]"
    WARNINGS_JSON="[]"
    if [ "$TOTAL_ISSUES" -gt 0 ]; then
        ISSUES_JSON=$(printf '%s\n' "${ISSUES[@]}" | python3 -c "import sys,json; print(json.dumps([l.strip() for l in sys.stdin]))")
    fi
    if [ "$TOTAL_WARNINGS" -gt 0 ]; then
        WARNINGS_JSON=$(printf '%s\n' "${WARNINGS[@]}" | python3 -c "import sys,json; print(json.dumps([l.strip() for l in sys.stdin]))")
    fi

    cat <<ENDJSON
{"status":"${STATUS}","issues":${ISSUES_JSON},"warnings":${WARNINGS_JSON},"host":"${MACOS_HOST:-localhost}","timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","disk_pct":${DISK_PCT},"cpu_load_pct":${LOAD_PCT},"mem_pct":${MEM_PCT}}
ENDJSON
fi

if [ "$TOTAL_ISSUES" -gt 0 ]; then
    log_err "Health check FAILED: ${TOTAL_ISSUES} critical issue(s), ${TOTAL_WARNINGS} warning(s)"
    exit 1
elif [ "$TOTAL_WARNINGS" -gt 0 ]; then
    log_warn "Health check passed with ${TOTAL_WARNINGS} warning(s)"
    exit 0
else
    log_ok "All checks healthy"
    exit 0
fi
