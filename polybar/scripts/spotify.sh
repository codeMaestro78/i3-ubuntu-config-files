#!/bin/bash
# ~/.config/polybar/scripts/spotify.sh
# Advanced Spotify/MPRIS module for Polybar
# Supports: Spotify, cmus, mpd, vlc, or any playerctl-compatible player

# ── Config ────────────────────────────────────────────────────────────────────
MAX_TITLE=12      # keep spotify compact so it does not hide later modules
FILL_CHAR="━"
EMPTY_CHAR="─"
# ─────────────────────────────────────────────────────────────────────────────

# ── Player detection ──────────────────────────────────────────────────────────
PLAYER=$(playerctl -l 2>/dev/null | grep -i spotify | head -1)
[ -z "$PLAYER" ] && PLAYER=$(playerctl -l 2>/dev/null | head -1)
[ -z "$PLAYER" ] && exit 0

STATUS=$(playerctl -p "$PLAYER" status 2>/dev/null)
[ -z "$STATUS" ] && exit 0

case "$STATUS" in
    Playing)  ICON="%{F#1db954}▶%{F-}" ;;
    Paused)   ICON="%{F#4a7a6a}⏸%{F-}" ;;
    *)        exit 0 ;;
esac

# ── Metadata ──────────────────────────────────────────────────────────────────
ARTIST=$(playerctl -p "$PLAYER" metadata artist 2>/dev/null)
TITLE=$( playerctl -p "$PLAYER" metadata title  2>/dev/null)
[ -z "$TITLE" ] && exit 0

if [ -n "$ARTIST" ]; then
    LABEL="$ARTIST – $TITLE"
else
    LABEL="$TITLE"
fi

if [ ${#LABEL} -gt $MAX_TITLE ]; then
    LABEL="${LABEL:0:$MAX_TITLE}…"
fi

# ── Progress bar + time ───────────────────────────────────────────────────────
echo "$ICON $LABEL"
