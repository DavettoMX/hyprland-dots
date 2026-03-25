#!/usr/bin/env bash

divider="─────────────"
goback="← Volver"
THEME="$HOME/.config/rofi/wifi/list.rasi"

power_on() {
    bluetoothctl show | grep -q "Powered: yes"
}

toggle_power() {
    if power_on; then
        bluetoothctl power off
        notify-send "Bluetooth" "Bluetooth desactivado"
    else
        rfkill unblock bluetooth 2>/dev/null
        bluetoothctl power on
        notify-send "Bluetooth" "Bluetooth activado"
        sleep 1
    fi
    show_menu
}

scan_on() {
    bluetoothctl show | grep -q "Discovering: yes"
}

toggle_scan() {
    if scan_on; then
        kill $(pgrep -f "bluetoothctl scan on") 2>/dev/null
        bluetoothctl scan off
    else
        bluetoothctl scan on &
        notify-send "Bluetooth" "Escaneando dispositivos..."
        sleep 4
    fi
    show_menu
}

device_connected() {
    bluetoothctl info "$1" | grep -q "Connected: yes"
}

device_paired() {
    bluetoothctl info "$1" | grep -q "Paired: yes"
}

get_device_battery() {
    bluetoothctl info "$1" | grep "Battery Percentage" | awk -F'[()]' '{print $2}'
}

toggle_connection() {
    local mac="$1"
    local name="$2"
    
    if device_connected "$mac"; then
        bluetoothctl disconnect "$mac"
        notify-send "Bluetooth" "Desconectado de $name"
    else
        notify-send "Bluetooth" "Conectando a $name..."
        bluetoothctl connect "$mac" && \
            notify-send "Bluetooth" "Conectado a $name" || \
            notify-send "Bluetooth" "Error al conectar con $name"
    fi
}

device_menu() {
    local device="$1"
    local mac=$(echo "$device" | awk '{print $2}')
    local name=$(echo "$device" | cut -d' ' -f3-)
    
    local connected="Desconectado"
    device_connected "$mac" && connected="Conectado"
    
    local battery=$(get_device_battery "$mac")
    local battery_info=""
    [[ -n "$battery" ]] && battery_info="󰁹 $battery"
    
    local options="Estado: $connected $battery_info\n$divider\n"
    
    if device_connected "$mac"; then
        options+="󰂲  Desconectar\n"
    else
        options+="󰂱  Conectar\n"
    fi
    
    if device_paired "$mac"; then
        options+="󰆴  Olvidar dispositivo\n"
    else
        options+="󰄬  Emparejar\n"
    fi
    
    options+="$divider\n$goback"
    
    local chosen=$(echo -e "$options" | rofi -dmenu -theme "$THEME" -p "$name")
    
    case "$chosen" in
        *"Desconectar"*)
            bluetoothctl disconnect "$mac"
            notify-send "Bluetooth" "Desconectado de $name"
            show_menu
            ;;
        *"Conectar"*)
            toggle_connection "$mac" "$name"
            show_menu
            ;;
        *"Olvidar"*)
            bluetoothctl remove "$mac"
            notify-send "Bluetooth" "Dispositivo $name eliminado"
            show_menu
            ;;
        *"Emparejar"*)
            bluetoothctl pair "$mac" && \
                notify-send "Bluetooth" "Emparejado con $name" || \
                notify-send "Bluetooth" "Error al emparejar"
            device_menu "$device"
            ;;
        *"Volver"*)
            show_menu
            ;;
    esac
}

show_menu() {
    local options=""
    
    if power_on; then
        local paired_devices=$(bluetoothctl devices Paired 2>/dev/null || bluetoothctl paired-devices)
        
        while read -r line; do
            [[ -z "$line" ]] && continue
            local mac=$(echo "$line" | awk '{print $2}')
            local name=$(echo "$line" | cut -d' ' -f3-)
            [[ -z "$mac" ]] && continue
            
            local icon="󰂴"
            local status=""
            
            if device_connected "$mac"; then
                icon="󰂱"
                local battery=$(get_device_battery "$mac")
                [[ -n "$battery" ]] && status=" 󰁹 $battery"
            fi
            
            options+="$icon  $name$status\n"
        done <<< "$paired_devices"
        
        options+="$divider\n"
        
        if scan_on; then
            options+="󰂰  Detener escaneo\n"
        else
            options+="󰂰  Buscar dispositivos\n"
        fi
        
        options+="󰂲  Desactivar Bluetooth\n"
    else
        options+="󰂯  Activar Bluetooth\n"
    fi
    
    options+="󰒓  Abrir configuración"
    
    local chosen=$(echo -e "$options" | rofi -dmenu -theme "$THEME" -p "Bluetooth")
    
    case "$chosen" in
        *"Activar Bluetooth"*|*"Desactivar Bluetooth"*)
            toggle_power
            ;;
        *"Buscar dispositivos"*|*"Detener escaneo"*)
            toggle_scan
            ;;
        *"Abrir configuración"*)
            blueman-manager &
            ;;
        ""|"$divider")
            exit 0
            ;;
        *)
            local name=$(echo "$chosen" | sed 's/^[^ ]* *//' | sed 's/ 󰁹.*$//')
            local device=$(bluetoothctl devices | grep "$name")
            [[ -n "$device" ]] && device_menu "$device"
            ;;
    esac
}

show_menu
