#!/usr/bin/env bash

set -euo pipefail

TMPBG="$(mktemp /tmp/lock_bg.XXXXXX).png"
TMPFINAL="$(mktemp /tmp/lock_final.XXXXXX).png"

cleanup() {
    rm -f "$TMPBG" "$TMPFINAL"
}
trap cleanup EXIT

for cmd in scrot convert identify i3lock; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "Missing dependency: $cmd" >&2
        exit 1
    }
done

TIME="$(date +"%H:%M")"
DATE="$(date +"%A, %d %B %Y")"
DAY_TAG="$(date +"%Z")"

USER_NAME="$(getent passwd "${USER:-$(id -un)}" | cut -d: -f5 | cut -d, -f1)"
USER_NAME="${USER_NAME:-${USER:-$(id -un)}}"

HOUR="$(date +"%H")"
if [ "$HOUR" -ge 5 ] && [ "$HOUR" -lt 12 ]; then
    GREET="Good Morning"
elif [ "$HOUR" -ge 12 ] && [ "$HOUR" -lt 17 ]; then
    GREET="Good Afternoon"
elif [ "$HOUR" -ge 17 ] && [ "$HOUR" -lt 21 ]; then
    GREET="Good Evening"
else
    GREET="Good Night"
fi

scrot -o "$TMPBG"

if ! identify "$TMPBG" >/dev/null 2>&1; then
    echo "Failed to capture a valid screenshot for lockscreen." >&2
    exit 1
fi

W="$(identify -format "%w" "$TMPBG")"
H="$(identify -format "%h" "$TMPBG")"
CX=$((W / 2))

HERO_Y=$((H * 24 / 100))
HERO_X1=$((CX - 330))
HERO_Y1=$((HERO_Y - 132))
HERO_X2=$((CX + 330))
HERO_Y2=$((HERO_Y + 88))

PILL_X1=$((CX - 210))
PILL_Y1=$((H * 83 / 100))
PILL_X2=$((CX + 210))
PILL_Y2=$((PILL_Y1 + 42))

DATE_Y=$((HERO_Y + 20))
GREETING_Y=$((HERO_Y + 58))

convert "$TMPBG" \
    -filter Gaussian -resize 12.5% -resize 800% \
    \( -size "${W}x${H}" radial-gradient:'#00000000-#02040acc' \) -compose multiply -composite \
    -fill "#081018aa" -colorize 28 \
    -fill "#0d1721" -colorize 26 \
    -fill "#72d5ff" -draw "color 0,0 reset" \
    -fill "#0a1018" -draw "rectangle 0,0 ${W},${H}" -alpha set -channel A -evaluate set 0 +channel \
    "$TMPFINAL"

convert "$TMPBG" \
    -filter Gaussian -resize 12.5% -resize 800% \
    \( -size "${W}x${H}" radial-gradient:'#00000000-#02040acc' \) -compose multiply -composite \
    -fill "#081018" -colorize 38 \
    -fill "#02050a" -colorize 42 \
    \( -size "${W}x${H}" gradient:'#12202d00-#05070bcc' -rotate 90 \) -compose screen -composite \
    -fill "#00000055" -draw "rectangle 0,0 ${W},${H}" \
    -fill "#08141e88" -stroke "#8bd5ff66" -strokewidth 2 \
    -draw "roundrectangle ${HERO_X1},${HERO_Y1} ${HERO_X2},${HERO_Y2} 24,24" \
    -fill "#00000066" -stroke "#ffffff18" -strokewidth 1 \
    -draw "roundrectangle ${PILL_X1},${PILL_Y1} ${PILL_X2},${PILL_Y2} 18,18" \
    -stroke "#7dcfffcc" -strokewidth 2 \
    -draw "line $((CX - 210)),$((HERO_Y - 2)) $((CX + 210)),$((HERO_Y - 2))" \
    -fill "#cfe7ff" -font "DejaVu-Sans-Bold" -pointsize 86 \
    -gravity North -annotate +0+$((HERO_Y1 + 26)) "$TIME" \
    -fill "#89b4fa" -font "DejaVu-Sans" -pointsize 20 \
    -gravity North -annotate +0+$DATE_Y "$DATE  •  $DAY_TAG" \
    -fill "#9ccfd8" -font "DejaVu-Sans" -pointsize 18 \
    -gravity North -annotate +0+$GREETING_Y "$GREET, $USER_NAME" \
    -fill "#6c8099" -font "DejaVu-Sans" -pointsize 14 \
    -gravity South -annotate +0+$((H - PILL_Y1 - 28)) "Press any key, then enter password to unlock" \
    "$TMPFINAL"

i3lock \
    --nofork \
    --image="$TMPFINAL"
