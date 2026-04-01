#!/bin/bash
# ~/.config/polybar/scripts/uptime.sh
# Advanced uptime module — shows uptime + color-coded load average

# ── Config ────────────────────────────────────────────────────────────────────
SHOW_LOAD=true        # show CPU load average (1min)
LOAD_WARN=1.5         # load avg threshold → yellow
LOAD_CRIT=3.0         # load avg threshold → red
# ─────────────────────────────────────────────────────────────────────────────

# ── Uptime ────────────────────────────────────────────────────────────────────
UPTIME_RAW=$(awk '{print int($1)}' /proc/uptime)

DAYS=$((UPTIME_RAW / 86400))
HOURS=$(( (UPTIME_RAW % 86400) / 3600 ))
MINS=$(( (UPTIME_RAW % 3600) / 60 ))

if   [ $DAYS  -gt 0 ]; then UPTIME_STR="${DAYS}d ${HOURS}h ${MINS}m"
elif [ $HOURS -gt 0 ]; then UPTIME_STR="${HOURS}h ${MINS}m"
else                        UPTIME_STR="${MINS}m"
fi

# Color uptime: green under 1d, yellow 1-7d, red 7d+ (long uptimes = no reboots)
if   [ $DAYS -ge 7 ]; then UPTIME_OUT="%{F#f7c948}${UPTIME_STR}%{F-}"
elif [ $DAYS -ge 1 ]; then UPTIME_OUT="%{F#c8fce8}${UPTIME_STR}%{F-}"
else                       UPTIME_OUT="%{F#4a7a6a}${UPTIME_STR}%{F-}"
fi

# ── Load average ──────────────────────────────────────────────────────────────
if $SHOW_LOAD; then
    LOAD=$(awk '{print $1}' /proc/loadavg)

    # Compare floats using awk
    IS_CRIT=$(awk -v l="$LOAD" -v t="$LOAD_CRIT" 'BEGIN{print (l+0 >= t+0)}')
    IS_WARN=$(awk -v l="$LOAD" -v t="$LOAD_WARN" 'BEGIN{print (l+0 >= t+0)}')

    if   [ "$IS_CRIT" = "1" ]; then LOAD_OUT="%{F#ff3b5c}󰔐 ${LOAD}%{F-}"
    elif [ "$IS_WARN" = "1" ]; then LOAD_OUT="%{F#f7c948}󰔐 ${LOAD}%{F-}"
    else                            LOAD_OUT="%{F#4a7a6a}󰔐 ${LOAD}%{F-}"
    fi

    echo "󰅐 $UPTIME_OUT  $LOAD_OUT"
else
    echo "󰅐 $UPTIME_OUT"
fi
