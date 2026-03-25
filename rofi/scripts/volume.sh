#!/usr/bin/env bash

THEME="$HOME/.config/rofi/wifi/list.rasi"

volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')
muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED && echo "true" || echo "false")

# Get sinks using pactl (handles Bluetooth properly unlike wpctl status)
get_sinks() {
    default_sink=$(pactl get-default-sink)
    LANG=C pactl list sinks | awk '
        /^Sink #/{ id=$2; gsub(/#/,"",id); name=""; desc="" }
        /^\tName:/{ name=$2 }
        /^\tDescription:/{ sub(/^\tDescription: /,""); desc=$0 }
        name != "" && desc != "" {
            print name "|" desc
            name=""; desc=""
        }
    ' | while IFS='|' read -r name desc; do
        if [[ "$name" == "$default_sink" ]]; then
            echo "●  $desc|$name"
        else
            echo "○  $desc|$name"
        fi
    done
}

menu=""
if [[ "$muted" == "true" ]]; then
    menu+="󰖁  Activar sonido\n"
else
    menu+="󰝟  Silenciar\n"
fi
menu+="󰕾  Volumen: $volume%\n"
menu+="───────────────────\n"

sinks=$(get_sinks)
while IFS= read -r sink; do
    [[ -z "$sink" ]] && continue
    display=$(echo "$sink" | cut -d'|' -f1)
    menu+="$display\n"
done <<< "$sinks"

menu+="───────────────────\n"
menu+="󰒓  Abrir mezclador"

chosen=$(echo -e "$menu" | rofi -dmenu -theme "$THEME" -p "Audio")

case "$chosen" in
    *"Activar sonido"*|*"Silenciar"*)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    *"Abrir mezclador"*)
        pavucontrol &
        ;;
    "●"*|"○"*)
        display=$(echo "$chosen" | sed 's/^[●○]  //')
        sink_name=$(echo "$sinks" | grep "$display" | cut -d'|' -f2)
        if [[ -n "$sink_name" ]]; then
            pactl set-default-sink "$sink_name"
            # Move all running audio streams to the new sink
            pactl list sink-inputs short | awk '{print $1}' | while read -r input_id; do
                pactl move-sink-input "$input_id" "$sink_name"
            done
            desc=$(echo "$chosen" | sed 's/^[●○]  //')
            notify-send -t 2000 "Audio" "Salida: $desc"
        fi
        ;;
esac
