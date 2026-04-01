#!/usr/bin/env bash

governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
source_mode=$(tlp-stat -s 2>/dev/null | awk -F'= ' '/Mode[[:space:]]*=/{print $2; exit}')

case "$governor" in
  performance)
    if [ "$source_mode" = "AC" ]; then
      printf '%%{F#a6e3a1}󰓅%%{F-} %%{F#cdd6f4}performance%%{F-}\n'
    else
      printf '%%{F#fab387}󰓅%%{F-} %%{F#cdd6f4}boost%%{F-}\n'
    fi
    ;;
  powersave)
    if [ "$source_mode" = "AC" ]; then
      printf '%%{F#89dceb}󱐋%%{F-} %%{F#cdd6f4}balanced%%{F-}\n'
    else
      printf '%%{F#f9e2af}󰾆%%{F-} %%{F#cdd6f4}saver%%{F-}\n'
    fi
    ;;
  *)
    printf '%%{F#6c7086}󱄅%%{F-} %%{F#7f849c}power%%{F-}\n'
    ;;
esac
