k#!/bin/bash
# ~/.config/polybar/scripts/weather.sh
# Advanced weather module — temp color-coded, feels-like, humidity, wind
# Uses wttr.in (no API key needed)

# ── Config ────────────────────────────────────────────────────────────────────
CITY="Ahmedabad"
CACHE="/tmp/polybar_weather_cache"
CACHE_AGE=1800        # seconds between API calls (30 min)
UNIT="m"              # m = metric (°C), u = imperial (°F)
SHOW_FEELS=true       # show feels-like temp
SHOW_HUMIDITY=true    # show humidity %
SHOW_WIND=false       # show wind speed (makes bar wider)
# ─────────────────────────────────────────────────────────────────────────────

# ── Cache check ───────────────────────────────────────────────────────────────
if [ -f "$CACHE" ] && [ $(( $(date +%s) - $(stat -c %Y "$CACHE") )) -lt $CACHE_AGE ]; then
    cat "$CACHE"
    exit 0
fi

# ── Fetch — one call, all fields ──────────────────────────────────────────────
# Format codes: %c=icon %t=temp %f=feels-like %h=humidity %w=wind %C=condition
RAW=$(curl -sf --max-time 6 \
    "https://wttr.in/${CITY}?format=%c|%t|%f|%h|%w&${UNIT}" 2>/dev/null)

if [ -z "$RAW" ]; then
    [ -f "$CACHE" ] && cat "$CACHE" && exit 0
    echo "%{F#ff3b5c}󰖐%{F-} %{F#4a7a6a}offline%{F-}"
    exit 0
fi

# ── Parse ─────────────────────────────────────────────────────────────────────
ICON=$(    echo "$RAW" | cut -d'|' -f1 | xargs)
TEMP=$(    echo "$RAW" | cut -d'|' -f2 | tr -d '+°C°F ')  # bare number
FEELS=$(   echo "$RAW" | cut -d'|' -f3 | tr -d '+°C°F ')
HUMIDITY=$(echo "$RAW" | cut -d'|' -f4 | tr -d '%')
WIND=$(    echo "$RAW" | cut -d'|' -f5 | xargs)

# ── Temperature color ─────────────────────────────────────────────────────────
# Thresholds assume Celsius; adjust if using imperial
TEMP_COLOR=$(awk -v t="$TEMP" 'BEGIN {
    if      (t+0 >= 40) print "#ff3b5c"   # extreme heat  → red
    else if (t+0 >= 32) print "#ff8c42"   # hot           → orange
    else if (t+0 >= 25) print "#f7c948"   # warm          → yellow
    else if (t+0 >= 15) print "#00ff9c"   # comfortable   → green
    else if (t+0 >= 5 ) print "#00e5ff"   # cool          → cyan
    else                print "#00b4ff"   # cold          → blue
}')

# ── Humidity color ────────────────────────────────────────────────────────────
HUMID_COLOR=$(awk -v h="$HUMIDITY" 'BEGIN {
    if      (h+0 >= 80) print "#ff3b5c"
    else if (h+0 >= 60) print "#f7c948"
    else                print "#4a7a6a"
}')

# ── Assemble output ───────────────────────────────────────────────────────────
# Restore unit suffix
[ "$UNIT" = "m" ] && SUFFIX="°C" || SUFFIX="°F"

OUT="$ICON %{F${TEMP_COLOR}}${TEMP}${SUFFIX}%{F-}"

if $SHOW_FEELS && [ -n "$FEELS" ] && [ "$FEELS" != "$TEMP" ]; then
    OUT="$OUT %{F#4a7a6a}(feels ${FEELS}${SUFFIX})%{F-}"
fi

if $SHOW_HUMIDITY && [ -n "$HUMIDITY" ]; then
    OUT="$OUT  %{F${HUMID_COLOR}}󰖝 ${HUMIDITY}%%%{F-}"
fi

if $SHOW_WIND && [ -n "$WIND" ]; then
    OUT="$OUT  %{F#4a7a6a}󰇛 ${WIND}%{F-}"
fi

# ── Cache and output ──────────────────────────────────────────────────────────
echo "$OUT" | tee "$CACHE"
