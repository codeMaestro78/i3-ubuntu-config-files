#!/usr/bin/env bash

sec=$(date +%S)
frame=$((10#$sec % 4))

powered=$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered/ {print $2; exit}')
if [ "$powered" != "yes" ]; then
  printf '%%{F#6c7086}󰂲%%{F-} %%{F#7f849c}off%%{F-}\n'
  exit 0
fi

connected=$(bluetoothctl devices Connected 2>/dev/null | head -n 1)
if [ -n "$connected" ]; then
  name=${connected#Device }
  name=${name#* }
  short=${name:0:12}
  [ ${#name} -gt 12 ] && short="${short}…"

  wave_frames=("▁▂▃" "▂▃▄" "▃▄▅" "▂▃▄")
  spark_colors=("#6c7086" "#b4befe" "#cba6f7" "#f5c2e7")

  printf '%%{F#cba6f7}󰂱%%{F-} %%{F#cdd6f4}%s%%{F-} %%{F#b4befe}%s%%{F-} %%{F%s}•%%{F-}\n' \
    "$short" "${wave_frames[$frame]}" "${spark_colors[$frame]}"
else
  idle_icons=("󰂯" "󰂯" "󰂰" "󰂰")
  idle_glow=("#74c7ec" "#89dceb" "#b4befe" "#cba6f7")
  scan_dots=("·  " "•  " "•• " "•••")

  printf '%%{F%s}%s%%{F-} %%{F#bac2de}ready%%{F-} %%{F%s}%s%%{F-}\n' \
    "${idle_glow[$frame]}" "${idle_icons[$frame]}" "${idle_glow[$frame]}" "${scan_dots[$frame]}"
fi
