#!/usr/bin/env bash

sec=$(date +%S)
frame=$((10#$sec % 4))

state=$(nmcli -t -f WIFI g 2>/dev/null)
if [ "$state" != "enabled" ]; then
  printf '%%{F#f38ba8}󰤮%%{F-} %%{F#7f849c}off%%{F-}\n'
  exit 0
fi

active=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2":"$3; exit}')
if [ -z "$active" ]; then
  scan_icons=("󰤯" "󰤟" "󰤢" "󰤥")
  scan_dots=("·  " "•  " "•• " "•••")
  printf '%%{F#f9e2af}%s%%{F-} %%{F#bac2de}scan%%{F-} %%{F#74c7ec}%s%%{F-}\n' \
    "${scan_icons[$frame]}" "${scan_dots[$frame]}"
  exit 0
fi

ssid=${active%:*}
signal=${active##*:}
[ -z "$signal" ] && signal=0

if [ "$signal" -ge 80 ]; then
  icon="󰤨"
  color="#a6e3a1"
  bars="▂▄▆█"
elif [ "$signal" -ge 60 ]; then
  icon="󰤥"
  color="#89dceb"
  bars="▂▄▆_"
elif [ "$signal" -ge 40 ]; then
  icon="󰤢"
  color="#f9e2af"
  bars="▂▄__"
elif [ "$signal" -ge 20 ]; then
  icon="󰤟"
  color="#fab387"
  bars="▂___"
else
  icon="󰤯"
  color="#f38ba8"
  bars="____"
fi

ssid_short=${ssid:0:12}
[ ${#ssid} -gt 12 ] && ssid_short="${ssid_short}…"

pulse_colors=("#45475a" "#74c7ec" "#89dceb" "#a6e3a1")
pulse="%{F${pulse_colors[$frame]}}•%{F-}"

printf '%%{F%s}%s%%{F-} %%{F#cdd6f4}%s%%{F-} %%{F%s}%s%%{F-} %s\n' \
  "$color" "$icon" "$ssid_short" "$color" "$bars" "$pulse"
