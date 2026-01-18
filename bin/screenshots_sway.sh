#!/usr/bin/env bash
set -euo pipefail

MAIN_DIR="${HOME}/Pictures/Screenshots"
YEAR=$(date '+%Y')
MONTH=$(date '+%B')
SAVE_DIR="${MAIN_DIR}/${YEAR}/${MONTH}"
mkdir -p "$SAVE_DIR"

NAME="$(date '+%Y-%m-%d_%H-%M-%S').png"
FILE="${SAVE_DIR}/${NAME}"

MODE="${1:-monitor}"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    notify-send "❌ Screenshot failed" "Missing dependency: $1"
    exit 1
  }
}

need swaymsg
need grim
need wl-copy
need jq
need notify-send
need slurp

# Find the focused *window-ish* node.
# We prefer nodes that actually represent a view: app_id (Wayland native) or window_properties (Xwayland).
FOCUSED_JSON="$(
  swaymsg -t get_tree | jq -c '
    .. | objects
    | select(.focused? == true)
    | select((.app_id? != null) or (.window_properties? != null))
    | { x:.rect.x, y:.rect.y, w:.rect.width, h:.rect.height, out:(.output // "") }
  ' | head -n 1
)"

if [[ -z "${FOCUSED_JSON}" ]]; then
  notify-send "❌ Screenshot failed" "No focused window found"
  exit 1
fi

FX="$(jq -r '.x' <<<"$FOCUSED_JSON")"
FY="$(jq -r '.y' <<<"$FOCUSED_JSON")"
FW="$(jq -r '.w' <<<"$FOCUSED_JSON")"
FH="$(jq -r '.h' <<<"$FOCUSED_JSON")"
FOCUSED_OUT="$(jq -r '.out' <<<"$FOCUSED_JSON")"

copy_and_notify() {
  wl-copy < "$FILE"
  notify-send -h string:x-canonical-private-synchronous:screenshot "$1" "Saved & copied: $FILE"
}

if [[ "$MODE" == "window" ]]; then
  grim -g "${FX},${FY} ${FW}x${FH}" "$FILE"
  copy_and_notify "📸 Screenshot (window)"
  exit 0
fi

if [[ "$MODE" == "cursor" ]]; then
  grim -g "$(slurp)" "$FILE"
  copy_and_notify "🖱️ Screenshot (cursor)"
  exit 0
fi

# Default: monitor containing focused window.
# If we can't determine output, fall back to the currently focused output.
if [[ -z "$FOCUSED_OUT" || "$FOCUSED_OUT" == "null" ]]; then
  FOCUSED_OUT="$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name' | head -n 1)"
fi

OUT_RECT="$(
  swaymsg -t get_outputs | jq -c --arg OUT "$FOCUSED_OUT" '
    .[] | select(.name == $OUT) | { x:.rect.x, y:.rect.y, w:.rect.width, h:.rect.height }
  ' | head -n 1
)"

if [[ -z "${OUT_RECT}" ]]; then
  notify-send "❌ Screenshot failed" "Could not determine output rect"
  exit 1
fi

MX="$(jq -r '.x' <<<"$OUT_RECT")"
MY="$(jq -r '.y' <<<"$OUT_RECT")"
MW="$(jq -r '.w' <<<"$OUT_RECT")"
MH="$(jq -r '.h' <<<"$OUT_RECT")"

grim -g "${MX},${MY} ${MW}x${MH}" "$FILE"
copy_and_notify "🖥️ Screenshot (monitor)"
