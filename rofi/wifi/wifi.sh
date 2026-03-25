#!/usr/bin/env bash

notify-send -t 2000 "WiFi" "Escaneando redes..."

LIST_THEME="$HOME/.config/rofi/wifi/list.rasi"
PASSWORD_THEME="$HOME/.config/rofi/wifi/password.rasi"
SSID_THEME="$HOME/.config/rofi/wifi/ssid.rasi"

wifi_status=$(nmcli -t -f WIFI general | tail -n1)

if [[ "$wifi_status" == "disabled" ]]; then
    choice=$(echo -e "Activar Wi-Fi" | rofi -dmenu -theme "$LIST_THEME" -p "WiFi")
    if [[ "$choice" == "Activar Wi-Fi" ]]; then
        nmcli radio wifi on
        sleep 2
        exec "$0"
    fi
    exit 0
fi

connected_ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^sí\|^yes' | cut -d: -f2- || echo "")

wifi_list=$(nmcli -t -f ssid,security dev wifi 2>/dev/null | awk -F: '
{
    icon = ($2 ~ /WPA|WEP|802\.1X/) ? "" : "";
    if ($1 != "") {
        printf "%s   %s\n", icon, $1
    }
}' | sort -u)

if [[ -n "$connected_ssid" ]]; then
    connection_status="   Conectado a $connected_ssid\n"
else
    connection_status=""
fi

menu="󰤭   Desactivar Wi-Fi\n${connection_status}󰒓   Configuración manual\n─────────────\n${wifi_list}"

choice=$(echo -e "$menu" | rofi -dmenu -theme "$LIST_THEME" -p "WiFi") || exit 0
choice=$(echo "$choice" | sed -E 's/^[^a-zA-Z0-9]+//')

case "$choice" in
    "Desactivar Wi-Fi")
        nmcli radio wifi off
        notify-send "WiFi" "WiFi desactivado"
        ;;
    "Configuración manual")
        ssid=$(rofi -dmenu -theme "$SSID_THEME" -p "SSID") || exit 0
        [[ -z "$ssid" ]] && exit 0
        password=$(rofi -dmenu -password -theme "$PASSWORD_THEME" -p "Contraseña") || exit 0
        nmcli dev wifi connect "$ssid" hidden yes password "$password" && \
            notify-send "WiFi" "Conectado a $ssid" || \
            notify-send "WiFi" "Error al conectar"
        ;;
    "Conectado a"*)
        kitty -e sh -c "nmcli dev wifi show-password; read -p 'Presiona Enter para cerrar...'"
        ;;
    ""|"─────────────")
        exit 0
        ;;
    *)
        if nmcli connection show "$choice" &>/dev/null; then
            nmcli connection up "$choice" && \
                notify-send "WiFi" "Conectado a $choice" || \
                notify-send "WiFi" "Error al conectar"
        else
            password=$(rofi -dmenu -password -theme "$PASSWORD_THEME" -p "Contraseña") || exit 0
            [[ -z "$password" ]] && exit 0
            nmcli dev wifi connect "$choice" password "$password" && \
                notify-send "WiFi" "Conectado a $choice" || \
                notify-send "WiFi" "Error al conectar"
        fi
        ;;
esac
