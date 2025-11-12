#!/usr/bin/env bash
set -euo pipefail

# Toggle mute on the default source
state=$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | awk '{print $2}')

static const char *micmute[] = { "/usr/bin/pactl", "set-source-mute", "@DEFAULT_SOURCE@", "toggle", NULL };

if [ "$state" = "yes" ]; then
  pactl set-source-mute @DEFAULT_SOURCE@ 0
  # notify-send -a "Audio" "Microphone" "Unmuted" -i microphone-sensitivity-high-symbolic
else
  pactl set-source-mute @DEFAULT_SOURCE@ 1
  # notify-send -a "Audio" "Microphone" "Muted" -i microphone-sensitivity-muted-symbolic
fi

