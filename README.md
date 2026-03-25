# hyprland-dots

My Hyprland desktop environment configuration for Fedora.

## Overview

- **WM:** [Hyprland](https://hyprland.org)
- **Bar:** Waybar
- **Terminal:** Kitty
- **Launcher:** Wofi / Rofi
- **Notifications:** SwayNC + Dunst
- **Lock:** Hyprlock
- **Power menu:** wlogout
- **Audio:** PipeWire + pactl + pamixer

## Structure

```
├── hypr/             # Hyprland + Hyprlock config
├── waybar/           # Status bar (workspaces, clock, media, cpu, audio, network, bluetooth)
├── rofi/             # Rofi scripts and themes
│   ├── scripts/      # Volume switcher, Bluetooth manager
│   └── wifi/         # WiFi connection manager
├── kitty/            # Terminal config
├── dunst/            # Notification daemon
├── swaync/           # Notification center
├── wlogout/          # Power/logout menu
└── wofi/             # App launcher + power menu
```

## Key Bindings

| Bind | Action |
|------|--------|
| `Super + Return` | Kitty terminal |
| `Super + D` | Wofi launcher |
| `Super + E` | Thunar file manager |
| `Super + Q` | Close window |
| `Super + N` | Toggle notifications |
| `Super + Escape` | Power menu |
| `Super + Shift + B` | Lock screen |
| `Super + H/J/K/L` | Move focus |
| `Print` | Screenshot |

## Audio

The Rofi volume script (`rofi/scripts/volume.sh`) supports:
- Volume control and mute toggle
- Audio sink switching (speakers, Bluetooth, AirPlay)
- Automatic migration of running audio streams when switching devices

## Dependencies

```
hyprland waybar kitty wofi rofi dunst swaync wlogout hyprlock
pipewire pamixer pavucontrol playerctl grim
```
