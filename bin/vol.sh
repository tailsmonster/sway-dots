#!/usr/bin/env bash
set -euo pipefail

step="+5%"

case "${1:-}" in
  up)
    pactl set-sink-volume @DEFAULT_SINK@ "$step"
    # hard clamp to 100%
    current=$(pactl get-sink-volume @DEFAULT_SINK@ | awk -F'/' 'NR==1{gsub(/%/,"",$2); print $2+0}')
    if [ "$current" -gt 100 ]; then
      pactl set-sink-volume @DEFAULT_SINK@ 100%
    fi
    ;;
  down)
    pactl set-sink-volume @DEFAULT_SINK@ "-5%"
    ;;
  mute)
    pactl set-sink-mute @DEFAULT_SINK@ toggle
    ;;
  *)
    echo "usage: vol.sh {up|down|mute}" >&2
    exit 1
    ;;
esac

# Notify (optional, comment out if you hate toasts)
# muted=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
# vol=$(pactl get-sink-volume @DEFAULT_SINK@ | awk -F'/' 'NR==1{gsub(/%/,"",$2); print $2+0}')
# if [ "$muted" = "yes" ]; then
#   notify-send -a "Audio" "Volume" "Muted" -i audio-volume-muted-symbolic
# else
#   notify-send -a "Audio" "Volume" "${vol}%" -i audio-volume-high-symbolic
# fi

