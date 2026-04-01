#!/usr/bin/env bash

sec=$(date +%S)
frame=$((10#$sec % 4))

if pgrep -x obs >/dev/null 2>&1; then
  rec_icons=("󰻃" "󰐃" "󰻃" "󰐃")
  rec_colors=("#f38ba8" "#ff5c7a" "#f38ba8" "#ff7a90")
  printf '%%{F%s}%s%%{F-} %%{F#f9e2af}rec%%{F-}\n' "${rec_colors[$frame]}" "${rec_icons[$frame]}"
  exit 0
fi

if pgrep -af ffmpeg | grep -Eq 'x11grab|kmsgrab|pipewire'; then
  rec_dots=("•  " "•• " "•••" " • ")
  printf '%%{F#f38ba8}󰻃%%{F-} %%{F#f9e2af}ffmpeg%%{F-} %%{F#fab387}%s%%{F-}\n' "${rec_dots[$frame]}"
  exit 0
fi

clip=$(xclip -o -selection clipboard 2>/dev/null | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g')

if [ -z "$clip" ]; then
  printf '%%{F#6c7086}󰅌%%{F-} %%{F#7f849c}empty%%{F-}\n'
  exit 0
fi

clip=${clip#"${clip%%[![:space:]]*}"}
clip_short=${clip:0:14}
[ ${#clip} -gt 14 ] && clip_short="${clip_short}…"

pulse=("·" "•" "●" "•")
colors=("#6c7086" "#74c7ec" "#89dceb" "#74c7ec")

printf '%%{F#89b4fa}󰅍%%{F-} %%{F#cdd6f4}%s%%{F-} %%{F%s}%s%%{F-}\n' \
  "$clip_short" "${colors[$frame]}" "${pulse[$frame]}"
