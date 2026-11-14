# Fedora Hyprland & Quickshell Dotfiles (End4 / Illogical Impulse)

Fully migrated and working dotfiles for **Fedora Linux** running **Hyprland 0.57+ (Native Lua config architecture)** with **Quickshell**.

## Features Included
- **Hyprland 0.57+ Native Lua Configuration**: Complete modular migration from legacy `.conf` into native Lua (`hyprland.lua`).
- **Smooth Window Drag & Drop**: Full mouse dragging support (`Super + LMB` to drag windows across monitors and workspaces, `Super + RMB` to resize).
- **Smooth Gestures & Animations**:
  - 3-finger and 4-finger horizontal touchpad workspace swipe.
  - Fluid `slidefade` workspace transition animations tuned with `menu_decel`.
- **Quickshell Desktop & Bar (`qs -c ii`)**: Integrated with all submodules (including `rounded-polygon-qmljs`).
- **Multi-Monitor & Drag & Drop Support**: Native support for dragging and dropping windows across screens and workspaces in Hyprland and Quickshell overview.

## Quick Installation / Restore

1. **Install dependencies on Fedora**:
   ```bash
   sudo dnf copr enable -y sdegler/hyprland
   sudo dnf install -y hyprland quickshell swww kitty grim slurp wl-clipboard
   ```

2. **Deploy configs**:
   ```bash
   cp -r hypr ~/.config/
   cp -r quickshell ~/.config/
   ```

3. **Reload Hyprland**:
   ```bash
   hyprctl reload
   ```
