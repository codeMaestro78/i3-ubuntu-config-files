#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  Battery — animated polybar script
#  States: charging (fill wave) | discharging (color ramp)
#          full (pulse glow)    | low (<20% blink warning)
# ─────────────────────────────────────────────────────────────

BAT_PATH="/sys/class/power_supply/BAT1"
CAPACITY=$(cat "$BAT_PATH/capacity" 2>/dev/null || echo 0)
STATUS=$(cat  "$BAT_PATH/status"   2>/dev/null || echo "Unknown")

# animation frame: cycles 0-3 every second
FRAME=$(( $(date +%s) % 4 ))

# ── Color based on level ──────────────────────────────────────
get_color() {
  local pct=$1
  if   [ "$pct" -ge 80 ]; then echo "#a6e3a1"   # green
  elif [ "$pct" -ge 60 ]; then echo "#94e2d5"   # teal
  elif [ "$pct" -ge 40 ]; then echo "#f9e2af"   # yellow
  elif [ "$pct" -ge 20 ]; then echo "#fab387"   # peach
  else                         echo "#f38ba8"   # red
  fi
}

# ── Battery icon based on level ───────────────────────────────
get_icon() {
  local pct=$1
  if   [ "$pct" -ge 90 ]; then echo "󰁹"
  elif [ "$pct" -ge 80 ]; then echo "󰂂"
  elif [ "$pct" -ge 70 ]; then echo "󰂁"
  elif [ "$pct" -ge 60 ]; then echo "󰂀"
  elif [ "$pct" -ge 50 ]; then echo "󰁿"
  elif [ "$pct" -ge 40 ]; then echo "󰁾"
  elif [ "$pct" -ge 30 ]; then echo "󰁽"
  elif [ "$pct" -ge 20 ]; then echo "󰁼"
  elif [ "$pct" -ge 10 ]; then echo "󰁻"
  else                         echo "󰁺"
  fi
}

COLOR=$(get_color "$CAPACITY")
ICON=$(get_icon "$CAPACITY")

# ── CHARGING ─────────────────────────────────────────────────
if [ "$STATUS" = "Charging" ]; then
  charge_icons=("󰁺" "󰁼" "󰁿" "󰂂")
  sparks=("⚡" "✦" "⚡" "✦")
  spark_colors=("#f9e2af" "#a6e3a1" "#f9e2af" "#94e2d5")

  charge_icon="${charge_icons[$FRAME]}"
  spark="${sparks[$FRAME]}"
  spark_color="${spark_colors[$FRAME]}"

  printf '%%{F%s}%s%%{F-} %%{F#cdd6f4}%s%%%%{F-} %%{F%s}%s%%{F-}\n' \
    "#00ff9c" "$charge_icon" "$CAPACITY" "$spark_color" "$spark"
  exit 0
fi

# ── FULL / NOT CHARGING (plugged in, 98%+) ────────────────────
if [ "$STATUS" = "Full" ] || { [ "$STATUS" = "Not charging" ] && [ "$CAPACITY" -ge 98 ]; }; then
  glow_colors=("#a6e3a1" "#94e2d5" "#a6e3a1" "#cba6f7")
  glow="${glow_colors[$FRAME]}"
  printf '%%{F%s}󰁹%%{F-} %%{F#cdd6f4}Full%%{F-} %%{F%s}✦%%{F-}\n' "$glow" "$glow"
  exit 0
fi

# ── LOW BATTERY (<= 20%) — blinking warning ───────────────────
if [ "$CAPACITY" -le 20 ]; then
  blink_icons=("󰁻" "󰂃" "󰁻" "󰂃")
  blink_colors=("#f38ba8" "#fab387" "#f38ba8" "#fab387")
  warn_msgs=("LOW" "!!!" "LOW" "!!!")

  blink_icon="${blink_icons[$FRAME]}"
  blink_color="${blink_colors[$FRAME]}"
  warn="${warn_msgs[$FRAME]}"

  printf '%%{F%s}%s%%{F-} %%{F%s}%s%%%%{F-} %%{F%s}%s%%{F-}\n' \
    "$blink_color" "$blink_icon" "$blink_color" "$CAPACITY" "$blink_color" "$warn"
  exit 0
fi

# ── DISCHARGING — normal ramp with animated dot ───────────────
idle_dots=("·" "•" "●" "•")
dot_colors=("$COLOR" "#cdd6f4" "$COLOR" "#cdd6f4")

dot="${idle_dots[$FRAME]}"
dot_color="${dot_colors[$FRAME]}"

printf '%%{F%s}%s%%{F-} %%{F#cdd6f4}%s%%%%{F-} %%{F%s}%s%%{F-}\n' \
  "$COLOR" "$ICON" "$CAPACITY" "$dot_color" "$dot"
