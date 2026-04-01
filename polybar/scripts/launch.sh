#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  Polybar Launch Script — Advanced                                    ║
# ║  Handles: multi-monitor, picom restart, hwmon detection,            ║
# ║           IPC spotify watcher, log rotation                         ║
# ╚══════════════════════════════════════════════════════════════════════╝

# ── Config ────────────────────────────────────────────────────────────────────
readonly POLYBAR_CONFIG="$HOME/.config/polybar/config.ini"
readonly PICOM_CONFIG="$HOME/.config/picom/picom.conf"
readonly BAR_NAME="main"
readonly LOG_FILE="/tmp/polybar.log"
readonly LOG_MAX_LINES=500        # rotate log when it exceeds this
readonly RESTART_PICOM=true       # set false to skip picom restart
readonly ENABLE_IPC_WATCHER=true  # set false to skip spotify IPC watcher
# ─────────────────────────────────────────────────────────────────────────────

# ── Logging ───────────────────────────────────────────────────────────────────
log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

rotate_log() {
    if [[ -f "$LOG_FILE" ]]; then
        local lines
        lines=$(wc -l < "$LOG_FILE")
        if (( lines > LOG_MAX_LINES )); then
            tail -n "$LOG_MAX_LINES" "$LOG_FILE" > "${LOG_FILE}.tmp"
            mv "${LOG_FILE}.tmp" "$LOG_FILE"
            log "Log rotated (was ${lines} lines)"
        fi
    fi
}

# ── Kill existing polybar ─────────────────────────────────────────────────────
terminate_polybar() {
    if pgrep -u "$UID" -x polybar > /dev/null 2>&1; then
        log "Terminating existing Polybar instances..."
        killall -q polybar
        local timeout=30 count=0
        while pgrep -u "$UID" -x polybar > /dev/null 2>&1; do
            sleep 0.1
            (( count++ ))
            if (( count >= timeout )); then
                log "WARNING: Force-killing stuck Polybar..."
                killall -9 polybar 2>/dev/null
                break
            fi
        done
        log "All Polybar instances terminated."
    fi
}

# ── Kill existing IPC watcher (spotify) ──────────────────────────────────────
terminate_ipc_watcher() {
    # Kill any leftover playerctl watcher spawned by a previous launch
    pkill -f "polybar_ipc_watch" 2>/dev/null || true
}

# ── Restart picom ─────────────────────────────────────────────────────────────
restart_picom() {
    $RESTART_PICOM || return 0

    if ! command -v picom > /dev/null 2>&1; then
        log "WARNING: picom not found, skipping compositor restart"
        return 0
    fi

    if [[ ! -f "$PICOM_CONFIG" ]]; then
        log "WARNING: picom config not found at $PICOM_CONFIG, skipping"
        return 0
    fi

    log "Restarting picom..."
    pkill -x picom 2>/dev/null || true
    sleep 0.3
    picom --config "$PICOM_CONFIG" &
    disown
    log "  → picom spawned (PID: $!)"
}

# ── Dynamic hwmon detection ───────────────────────────────────────────────────
# Exports HWMON_PATH so polybar's temperature module can use ${env:HWMON_PATH}
# Falls back to a hardcoded path if detection fails
detect_hwmon() {
    local hwmon_dir fallback="/sys/class/hwmon/hwmon6/temp1_input"

    # Look for coretemp (Intel) or k10temp (AMD)
    hwmon_dir=$(grep -rl "coretemp\|k10temp" /sys/class/hwmon/*/name 2>/dev/null \
                | head -1 | xargs -I{} dirname {} 2>/dev/null)

    if [[ -n "$hwmon_dir" ]] && [[ -f "${hwmon_dir}/temp1_input" ]]; then
        export HWMON_PATH="${hwmon_dir}/temp1_input"
        log "hwmon detected: $HWMON_PATH"
    elif [[ -f "$fallback" ]]; then
        export HWMON_PATH="$fallback"
        log "hwmon: using fallback $HWMON_PATH"
    else
        log "WARNING: No hwmon thermal sensor found — temperature module will be blank"
    fi
}

# ── Wait for WM to be ready ───────────────────────────────────────────────────
wait_for_wm() {
    local wm_pid
    for wm in i3 bspwm openbox herbstluftwm hyprland; do
        wm_pid=$(pgrep -u "$UID" -x "$wm" 2>/dev/null | head -1)
        if [[ -n "$wm_pid" ]]; then
            log "WM detected: $wm (PID: $wm_pid)"
            break
        fi
    done
    [[ -z "$wm_pid" ]] && log "WARNING: No known WM detected — launching anyway"
    sleep 0.4
}

# ── IPC Spotify watcher ───────────────────────────────────────────────────────
# Fires polybar IPC hook instantly on track change instead of waiting
# for the 2-second polling interval
start_ipc_watcher() {
    $ENABLE_IPC_WATCHER || return 0
    command -v playerctl  > /dev/null 2>&1 || return 0
    command -v polybar-msg > /dev/null 2>&1 || return 0

    # Named via argv[0] alias so terminate_ipc_watcher can pkill it cleanly
    bash -c '
        exec -a polybar_ipc_watch bash -c "
            playerctl --follow metadata --format \"{{status}} {{artist}} {{title}}\" \
                2>/dev/null | while IFS= read -r _line; do
                    polybar-msg action \"#spotify.hook.0\" 2>/dev/null || true
                done
        "
    ' &
    disown
    log "  → IPC spotify watcher spawned (PID: $!)"
}

# ── Launch bars ───────────────────────────────────────────────────────────────
launch_bars() {
    if ! command -v polybar > /dev/null 2>&1; then
        log "ERROR: polybar not found in PATH"
        exit 1
    fi

    if [[ ! -f "$POLYBAR_CONFIG" ]]; then
        log "ERROR: Config not found at $POLYBAR_CONFIG"
        exit 1
    fi

    if command -v xrandr > /dev/null 2>&1; then
        local monitors
        mapfile -t monitors < <(xrandr --query | awk '/ connected/ {print $1}')

        if [[ ${#monitors[@]} -eq 0 ]]; then
            log "WARNING: No connected monitors via xrandr"
            exit 1
        fi

        log "Launching on ${#monitors[@]} monitor(s): ${monitors[*]}"
        for monitor in "${monitors[@]}"; do
            MONITOR="$monitor" HWMON_PATH="$HWMON_PATH" \
                polybar --reload "$BAR_NAME" -c "$POLYBAR_CONFIG" \
                >> "$LOG_FILE" 2>&1 &
            log "  → Spawned on $monitor (PID: $!)"
            disown
        done
    else
        log "xrandr not available — launching on primary monitor"
        polybar --reload "$BAR_NAME" -c "$POLYBAR_CONFIG" >> "$LOG_FILE" 2>&1 &
        log "  → Spawned (PID: $!)"
        disown
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    rotate_log
    log "════════════════════════════════════"
    log "  Polybar launch started"
    log "════════════════════════════════════"

    terminate_ipc_watcher
    terminate_polybar
    restart_picom
    detect_hwmon
    wait_for_wm
    launch_bars
    start_ipc_watcher

    log "════════════════════════════════════"
    log "  Done"
    log "════════════════════════════════════"
}

main "$@"
