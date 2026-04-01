#!/usr/bin/env bash

# Compact animated datetime for Polybar.
# Keeps motion subtle so the center module stays readable.

hour_24=$(date +%H)
hour_12=$(date +%-I)
minute=$(date +%M)
second=$(date +%S)
day_name=$(date +%a)
day_num=$(date +%d)
month_name=$(date +%b)

second_num=$((10#$second))
hour_num=$((10#$hour_24))

c() { printf '%%{F%s}' "$1"; }
reset="%{F-}"

fg_ice=$(c "#8bd5ff")
fg_blue=$(c "#74c7ec")
fg_mauve=$(c "#cba6f7")
fg_rose=$(c "#f5c2e7")
fg_gold=$(c "#f9e2af")
fg_peach=$(c "#fab387")
fg_green=$(c "#a6e3a1")
fg_dim=$(c "#6c7086")
fg_text=$(c "#cdd6f4")

case "$day_name" in
  Mon) day_icon="󰃭"; day_color="$fg_blue" ;;
  Tue) day_icon="󰃮"; day_color="$fg_mauve" ;;
  Wed) day_icon="󰃯"; day_color="$fg_rose" ;;
  Thu) day_icon="󰃰"; day_color="$fg_gold" ;;
  Fri) day_icon="󰃱"; day_color="$fg_green" ;;
  Sat) day_icon="󰃲"; day_color="$fg_peach" ;;
  Sun) day_icon="󰃳"; day_color="$fg_rose" ;;
  *)   day_icon="󰃭"; day_color="$fg_blue" ;;
esac

if [ "$hour_num" -lt 6 ]; then
  phase_icon="󰖔"
  phase_color="$fg_mauve"
elif [ "$hour_num" -lt 12 ]; then
  phase_icon="󰖛"
  phase_color="$fg_gold"
elif [ "$hour_num" -lt 17 ]; then
  phase_icon="󰖙"
  phase_color="$fg_blue"
elif [ "$hour_num" -lt 20 ]; then
  phase_icon="󰖜"
  phase_color="$fg_peach"
else
  phase_icon="󰖔"
  phase_color="$fg_rose"
fi

clock_frames=("󱑊" "󱑋" "󱑌" "󱑍" "󱑎" "󱑏" "󱑐" "󱑑" "󱑒" "󱑓" "󱑔" "󱑕")
clock_icon="${clock_frames[$(((10#$minute / 5) % 12))]}"

if [ $((second_num % 2)) -eq 0 ]; then
  colon="${fg_blue}:${reset}"
else
  colon="${fg_dim}:${reset}"
fi

case $((second_num % 4)) in
  0) pulse="${fg_dim}·${reset}" ;;
  1) pulse="${fg_blue}•${reset}" ;;
  2) pulse="${fg_mauve}●${reset}" ;;
  3) pulse="${fg_rose}•${reset}" ;;
esac

case $((second_num / 15)) in
  0) progress="${fg_dim}▁${reset}${fg_dim}▁${reset}${fg_dim}▁${reset}${fg_dim}▁${reset}" ;;
  1) progress="${fg_blue}▂${reset}${fg_dim}▁${reset}${fg_dim}▁${reset}${fg_dim}▁${reset}" ;;
  2) progress="${fg_blue}▂${reset}${fg_mauve}▃${reset}${fg_dim}▁${reset}${fg_dim}▁${reset}" ;;
  3) progress="${fg_blue}▂${reset}${fg_mauve}▃${reset}${fg_rose}▄${reset}${fg_dim}▁${reset}" ;;
  *) progress="${fg_blue}▂${reset}${fg_mauve}▃${reset}${fg_rose}▄${reset}${fg_gold}▅${reset}" ;;
esac

printf '%s%s %s %s %s%s  %s%s%s%s%s%s  %s %s%s\n' \
  "$day_color" "$day_icon" "$day_name" "$day_num" "$month_name" "$reset" \
  "$phase_color" "$phase_icon" "$reset" \
  "${fg_text}${clock_icon} ${hour_12}${reset}" "$colon" "${fg_ice}${minute}${reset}" \
  "$progress" "$pulse" "${fg_dim}•${reset}"
