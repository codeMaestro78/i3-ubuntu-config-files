#!/usr/bin/env bash

set -euo pipefail

action="${1:-}"

case "$action" in
  reboot)
    prompt="Do you really want to reboot?"
    cmd="systemctl reboot"
    ;;
  poweroff)
    prompt="Do you really want to power off?"
    cmd="systemctl poweroff"
    ;;
  logout)
    prompt="Do you really want to log out?"
    cmd="i3-msg exit"
    ;;
  *)
    exit 2
    ;;
esac

choice=$(
  printf "No\nYes\n" | rofi -dmenu -i -p "$prompt" \
    -theme-str 'window {location: center; anchor: center; width: 420px; border-radius: 18px;} listview {lines: 2; columns: 1; spacing: 8px; scrollbar: false;} mainbox {children: [inputbar, listview]; spacing: 12px; padding: 18px;} inputbar {padding: 10px 12px;} element {padding: 10px 12px; border-radius: 12px;}'
)

[ "$choice" = "Yes" ] || exit 0
exec sh -c "$cmd"
