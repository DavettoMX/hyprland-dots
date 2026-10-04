#!/bin/bash

MONITOR="DP-2"
RESOLUTION="5120x1440"
WPE_ID="3259946859"

output_status() {
    current_hz=$(hyprctl monitors -j | jq -r '.[0].refreshRate' | cut -d'.' -f1)
    if [ "$current_hz" -ge 200 ] 2>/dev/null; then
        echo '{"text": "󰊴", "tooltip": "Gaming Mode (240Hz)", "class": "gaming-on"}'
    else
        echo '{"text": "󰊴", "tooltip": "Normal Mode (120Hz)", "class": "gaming-off"}'
    fi
}

toggle() {
    current_hz=$(hyprctl monitors -j | jq -r '.[0].refreshRate' | cut -d'.' -f1)

    if [ "$current_hz" -ge 200 ]; then
        # Gaming -> Normal
        hyprctl keyword monitor "$MONITOR,${RESOLUTION}@120,0x0,1"
        pkill -f linux-wallpaperengine
    else
        # Normal -> Gaming
        available=$(hyprctl monitors -j | jq -r '.[0].availableModes[]')
        if echo "$available" | grep -q "${RESOLUTION}@240"; then
            pkill -f linux-wallpaperengine 2>/dev/null
            hyprctl keyword monitor "$MONITOR,${RESOLUTION}@240,0x0,1"
            sleep 1
            linux-wallpaperengine --screen-root "$MONITOR" "$WPE_ID" &
            disown
        else
            notify-send -u normal "Gaming Mode" "240Hz no disponible. Activa el modo gaming en el monitor." -i dialog-warning
        fi
    fi
}

case "$1" in
    toggle) toggle ;;
    *)      output_status ;;
esac
