# Linux without Omarchy: terminal rain, the 3D pages as a screensaver, the GPU
# rain app, and the 3D desktop wallpaper on Wayland compositors with layer-shell.
# Sourced by install.sh.
# shellcheck shell=bash

WALLS="${XDG_DATA_HOME:-$HOME/.local/share}/asciipaper/user-wallpapers"
ASCIIPAPER_SRC="${XDG_DATA_HOME:-$HOME/.local/share}/asciipaper-src"

pkg_manager() {
  for pm in pacman apt-get dnf zypper; do have "$pm" && { echo "$pm"; return; }; done
}

# Install packages by generic name; each manager gets its own spelling.
pkg_install() {
  local pm; pm=$(pkg_manager)
  case $pm in
    pacman)  as_root pacman -S --needed --noconfirm "$@" ;;
    apt-get) as_root apt-get install -y "$@" ;;
    dnf)     as_root dnf install -y "$@" ;;
    zypper)  as_root zypper --non-interactive install "$@" ;;
    *) warn "no supported package manager; install yourself: $*"; return 1 ;;
  esac
}

# asciipaper needs wlr-layer-shell: Hyprland, Sway, niri, river, Wayfire, labwc, KDE.
layer_shell_desktop() {
  [[ -n ${WAYLAND_DISPLAY:-} ]] || return 1
  case "${XDG_CURRENT_DESKTOP:-}${DESKTOP_SESSION:-}" in
    *GNOME*|*gnome*) return 1 ;;
  esac
  return 0
}

lx_terminal() {
  section "Terminal rain"
  if have cmatrix; then skip "cmatrix already installed"; else pkg_install cmatrix && say "cmatrix"; fi
}

lx_screensaver() {
  section "3D Matrix screensaver"
  install_common_web
  install_file 755 "$REPO_DIR/bin/matrix-screensaver" "$BIN_DIR/matrix-screensaver"
  record "file:$BIN_DIR/matrix-screensaver"
  say "matrix-screensaver [3d|intense]  (fullscreen in your browser)"

  # The GPU rain app (matrix, redpill, trace) needs Qt 6 QML.
  local provider="${XDG_DATA_HOME:-$HOME/.local/share}/matrix-rain"
  if [[ -d $provider ]]; then
    skip "matrix-rain (matrix, redpill, trace) already installed"
  else
    if ! have qml6 && ! have qml; then
      case $(pkg_manager) in
        pacman)  pkg_install qt6-declarative ;;
        apt-get) pkg_install qml6-module-qtquick qml6-module-qtquick-window qml6-module-qtquick-shapes qt6-declarative-dev-tools ;;
        dnf)     pkg_install qt6-qtdeclarative ;;
      esac
    fi
    if have qml6 || have qml; then
      clone_or_update https://github.com/leandrolalanne/matrix-rain "$SRC_DIR/matrix-rain"
      ( cd "$SRC_DIR/matrix-rain" && run ./install.sh </dev/null | sed 's/^/    /' ) && {
        record "run:$SRC_DIR/matrix-rain/uninstall.sh"
        say "matrix / redpill / trace"
      }
    else
      warn "Qt 6 QML not available; skipped the GPU rain app (matrix, redpill)"
    fi
  fi
}

lx_wallpapers() {
  section "3D Matrix wallpaper (asciipaper)"
  if ! layer_shell_desktop; then
    warn "your desktop has no Wayland layer-shell (X11 or GNOME), so no live wallpaper; use matrix-screensaver instead"
    return
  fi
  local fresh=0
  if [[ -x $BIN_DIR/asciipaper ]]; then
    skip "asciipaper already installed"
  else
    case $(pkg_manager) in
      pacman)  pkg_install webkitgtk-6.0 python-gobject gtk4-layer-shell ;;
      apt-get) pkg_install gir1.2-webkit-6.0 gir1.2-gtk4layershell-1.0 python3-gi ;;
      dnf)     pkg_install webkitgtk6.0 gtk4-layer-shell python3-gobject ;;
      *) warn "install WebKitGTK 6.0, gtk4-layer-shell and PyGObject yourself"; return ;;
    esac || { warn "asciipaper dependencies failed; skipped"; return; }
    clone_or_update https://github.com/cYoren/asciipaper "$ASCIIPAPER_SRC"
    install_file 755 "$ASCIIPAPER_SRC/asciipaper" "$BIN_DIR/asciipaper"
    run mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/asciipaper"
    run cp -r "$ASCIIPAPER_SRC/wallpapers" "${XDG_DATA_HOME:-$HOME/.local/share}/asciipaper/"
    install_file 644 "$ASCIIPAPER_SRC/asciipaper.service" "$HOME/.config/systemd/user/asciipaper.service"
    run systemctl --user daemon-reload
    record "run:$ASCIIPAPER_SRC/install.sh uninstall"
    record "dir:$ASCIIPAPER_SRC"
    fresh=1
  fi
  run mkdir -p "$WALLS"
  run cp "$REPO_DIR/wallpapers/matrix-3d.html" "$REPO_DIR/wallpapers/matrix-3d-intense.html" "$WALLS/"
  record "file:$WALLS/matrix-3d.html"
  record "file:$WALLS/matrix-3d-intense.html"
  local engine="${XDG_CONFIG_HOME:-$HOME/.config}/asciipaper/engine.json"
  if [[ ! -f $engine ]]; then
    run mkdir -p "$(dirname "$engine")"
    ((DRY_RUN)) || printf '{\n  "fps": 60,\n  "idleFps": 30,\n  "quality": 1.0,\n  "pointer": 1.0\n}\n' >"$engine"
  fi
  install_file 755 "$REPO_DIR/bin/matrix-mode" "$BIN_DIR/matrix-mode"
  record "file:$BIN_DIR/matrix-mode"
  say "matrix-mode 3d | intense | off"
  if ((fresh)); then run "$BIN_DIR/matrix-mode" 3d; fi
}

install_platform() {
  want themes     && { section "Matrix themes"; skip "desktop themes are Omarchy-only"; }
  want terminal    && lx_terminal
  want screensaver && lx_screensaver
  want wallpapers  && lx_wallpapers
  return 0
}
