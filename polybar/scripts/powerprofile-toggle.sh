#!/usr/bin/env bash

current=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)

case "$current" in
  performance) target="powersave" ;;
  *) target="performance" ;;
esac

/usr/bin/lxqt-sudo /usr/bin/cpupower frequency-set -g "$target" >/dev/null 2>&1 &
