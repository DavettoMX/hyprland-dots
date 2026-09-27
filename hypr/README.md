# Hyprland Config - RTX 5070 Ti + Fedora

## Guia de recuperacion: Driver NVIDIA y kernel

Si despues de un reinicio Hyprland se reinicia en loop o Kitty no abre (ni en GNOME), probablemente el kernel se actualizo y rompio el driver NVIDIA.

### Diagnostico rapido

```bash
# Verificar si el modulo nvidia esta cargado
lsmod | grep nvidia

# Si no devuelve nada, el driver no esta activo
# Verificar version del kernel actual
uname -r

# Ver kernels instalados
rpm -q --last kernel | head -5

# Ver si hubo actualizaciones recientes
sudo dnf history list --reverse | tail -10
```

### Solucion inmediata: arrancar con kernel anterior

1. Reiniciar el PC
2. En GRUB, seleccionar **Advanced options for Fedora**
3. Elegir el kernel anterior que funcionaba (ej: `7.0.14`)
4. Shift o Esc durante el arranque si GRUB no aparece

### Recompilar driver para kernel nuevo

```bash
# Recompilar el modulo nvidia-open para el kernel actual
sudo akmods --force && sudo depmod -a

# Verificar que compilo correctamente
sudo modinfo nvidia | head -5
```

### Si falla la compilacion (version mismatch)

```bash
# 1. Quitar los kmod viejos que bloquean
sudo dnf remove 'kmod-nvidia*'

# 2. Reinstalar todo limpio (version nvidia-open)
sudo dnf install akmod-nvidia-open xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda

# 3. Compilar modulos
sudo akmods --force && sudo depmod -a

# 4. Reiniciar
sudo reboot
```

### Si hay conflicto de versiones entre kmod y librerias

```bash
# Sincronizar todas las librerias nvidia a la misma version
sudo dnf distro-sync '*nvidia*'
```

### Variables de entorno necesarias en hyprland.conf

```
cursor {
    no_hardware_cursors = true
}

env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
```

### Workaround: abrir Kitty sin GPU

```bash
LIBGL_ALWAYS_SOFTWARE=1 kitty
```

### Notas

- **GPU**: NVIDIA RTX 5070 Ti (Blackwell, GB203) + AMD Radeon integrada
- **Driver**: `akmod-nvidia-open` (los modulos open compilan mejor con kernels nuevos)
- **El driver cerrado `akmod-nvidia` no compila con kernels recientes** para esta GPU
- Fedora puede actualizar el kernel automaticamente — esto rompe el driver si no recompila
- `nvidia-smi` requiere el paquete `xorg-x11-drv-nvidia-cuda`
