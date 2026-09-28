# macOS: terminal rain, and the 3D Matrix rain as a real screensaver through
# WebViewScreenSaver, plus `matrix-screensaver` to run it on demand.
# Desktop themes are Omarchy-only. Sourced by install.sh.
# shellcheck shell=bash

WVSS_SAVER="$HOME/Library/Screen Savers/WebViewScreenSaver.saver"

need_brew() {
  if have brew; then return 0; fi
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x $b ]] && { eval "$("$b" shellenv)"; return 0; }
  done
  warn "Homebrew is needed for cmatrix and the screensaver module."
  if confirm "Install Homebrew now (from brew.sh)?"; then
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do [[ -x $b ]] && eval "$("$b" shellenv)"; done
  fi
  have brew
}

mac_terminal() {
  section "Terminal rain"
  if have cmatrix; then skip "cmatrix already installed"
  elif need_brew; then run brew install cmatrix && say "cmatrix"
  else warn "skipped cmatrix (no Homebrew)"; fi
}

# Point WebViewScreenSaver at the local 3D page. The module keeps its settings
# as ScreenSaverDefaults, ByHost, inside the legacy screen saver engine's
# container on current macOS (and outside it on older releases).
mac_configure_wvss() {
  local url=$1 uuid domain
  uuid=$(ioreg -rd1 -c IOPlatformExpertDevice 2>/dev/null | awk -F'"' '/IOPlatformUUID/{print $4}')
  [[ -n $uuid ]] || return 1
  for dir in "$HOME/Library/Containers/com.apple.ScreenSaver.Engine.legacyScreenSaver/Data/Library/Preferences/ByHost" \
             "$HOME/Library/Preferences/ByHost"; do
    run mkdir -p "$dir"
    domain="$dir/WebViewScreenSaver.$uuid"
    run defaults write "$domain" kScreenSaverFetchURLs -bool false
    run defaults write "$domain" kScreenSaverURLList -array "{ kScreenSaverURL = \"$url\"; kScreenSaverTime = -1; }"
  done
}

mac_screensaver() {
  section "3D Matrix screensaver"
  install_common_web
  install_file 755 "$REPO_DIR/bin/matrix-screensaver" "$BIN_DIR/matrix-screensaver"
  record "file:$BIN_DIR/matrix-screensaver"
  say "matrix-screensaver [3d|intense]  (fullscreen in your browser, any time)"

  if [[ -d $WVSS_SAVER ]]; then
    skip "WebViewScreenSaver already installed"
  elif need_brew; then
    run brew install --cask webviewscreensaver && record "cask:webviewscreensaver"
  else
    warn "skipped the system screensaver module (no Homebrew)"
    return
  fi

  local url="file://$THE_MATRIX_DATA/web/matrix-3d.html"
  if mac_configure_wvss "$url"; then
    say "WebViewScreenSaver set to the 3D rain"
  fi
  cat <<EOF

  ${B}One manual step:${N} open System Settings > Screen Saver (Wallpaper on
  newer macOS), pick ${B}WebViewScreenSaver${N}. If it does not show the rain,
  click Options and set the address to:
      $url
  For the intense version use:
      file://$THE_MATRIX_DATA/web/matrix-3d-intense.html
EOF
}

install_platform() {
  want themes     && { section "Matrix themes"; skip "desktop themes are Omarchy-only (Linux)"; }
  want wallpapers && { section "3D Matrix wallpaper"; skip "live desktop wallpapers are Linux-only; the 3D rain runs as your screensaver instead"; }
  want terminal    && mac_terminal
  want screensaver && mac_screensaver
  return 0
}
