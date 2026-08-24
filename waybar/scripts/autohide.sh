#!/bin/bash
# Auto-hide waybar: shows when cursor reaches top edge, hides when it leaves

THRESHOLD=5       # pixels from top edge to trigger show
BAR_ZONE=50       # pixels height where bar is considered "in use"
HIDE_DELAY=0.8    # seconds to wait before hiding

visible=false

while true; do
    pos=$(hyprctl cursorpos 2>/dev/null)
    y=$(echo "$pos" | cut -d',' -f2 | tr -d ' ')

    if [ -z "$y" ]; then
        sleep 0.3
        continue
    fi

    if [ "$y" -le "$THRESHOLD" ] && [ "$visible" = false ]; then
        pkill -SIGUSR1 waybar
        visible=true
    elif [ "$y" -gt "$BAR_ZONE" ] && [ "$visible" = true ]; then
        sleep "$HIDE_DELAY"
        # Re-check after delay in case cursor came back
        pos=$(hyprctl cursorpos 2>/dev/null)
        y=$(echo "$pos" | cut -d',' -f2 | tr -d ' ')
        if [ "$y" -gt "$BAR_ZONE" ]; then
            pkill -SIGUSR1 waybar
            visible=false
        fi
    fi

    sleep 0.2
done
