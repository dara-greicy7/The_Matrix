# Omarchy (Arch + Hyprland) installer: every Matrix theme, their extras, the
# video rain, the 3D wallpapers and the Matrix screensaver. Sourced by install.sh.
# shellcheck shell=bash

THEMES="$HOME/.config/omarchy/themes"
PLUGINS="$HOME/.config/omarchy/plugins"
HOOKS_SET="$HOME/.config/omarchy/hooks/theme-set.d"
WALLS="${XDG_DATA_HOME:-$HOME/.local/share}/asciipaper/user-wallpapers"
TINTERIAN_SRC="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-matrix-rain-src"
ASCIIPAPER_SRC="${XDG_DATA_HOME:-$HOME/.local/share}/asciipaper-src"

# repo URL | folder name under ~/.config/omarchy/themes
# Names are fixed where two repos would otherwise collide, or where a theme's own
# scripts expect a particular name (omatrix, enter-the-matrix).
OMARCHY_THEMES=(
  "https://github.com/BVisagie/omarchy-matrix-theme|matrix"
  "https://github.com/tymurbogach/omarchy-enter-the-matrix-theme|enter-the-matrix"
  "https://github.com/leandrolalanne/omarchy-omatrix-theme|omatrix"
  "https://github.com/0x1ocean/omarchy-omatrix-theme|omatrix-0x1ocean"
  "https://github.com/tmp75/omarchy-matrix-theme|matrix-tmp75"
  "https://github.com/CerealThriller/omarchy-the-matrix-theme|the-matrix"
  "https://github.com/codeclawd/omarchy-matrix-trilogy-theme|matrix-trilogy"
  "https://github.com/mathiasjons82-code/omarchy-matrix-sakura-theme|matrix-sakura"
  "https://github.com/nicogarazzo/omarchy-wake-up-neo-theme|wake-up-neo"
)
RBE_REPO="https://github.com/foucist/omarchy-rbe-matrix-themes"
RBE_VARIANTS=(rbe-matrix rbe-matrix-mid rbe-matrix-mild rbe-matrix-milder)

pac_install() {
  local missing=() p
  for p in "$@"; do pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p"); done
  ((${#missing[@]})) || return 0
  say "installing packages: ${missing[*]}"
  as_root pacman -S --needed --noconfirm "${missing[@]}"
}

aur_helper() { if have yay; then echo yay; elif have paru; then echo paru; fi; }

aur_install() {
  local missing=() p helper
  for p in "$@"; do pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p"); done
  ((${#missing[@]})) || return 0
  helper=$(aur_helper)
  [[ -n $helper ]] || { warn "no AUR helper (yay/paru) for: ${missing[*]}"; return 1; }
  say "installing from the AUR with $helper: ${missing[*]}"
  if [[ -t 0 ]]; then run "$helper" -S --needed --noconfirm "${missing[@]}"
  else run "$helper" -S --needed --noconfirm --sudo pkexec "${missing[@]}"; fi
}

install_hook() { # <event> <file>
  local name; name=$(basename "$2")
  if [[ -e $HOME/.config/omarchy/hooks/$1.d/$name ]]; then skip "hook $1/$name already installed"; return; fi
  run omarchy hook install "$1" "$2" >/dev/null
  record "hook:$1/$name"
  say "hook $1/$name"
}

# --- themes -------------------------------------------------------------------

om_themes() {
  section "Matrix themes"
  run mkdir -p "$THEMES"

  # An earlier `omarchy theme install` of 0x1ocean's repo is named `omatrix`, the
  # name leandrolalanne's scripts need. Move it to its own name first.
  if [[ -d $THEMES/omatrix && $(git_origin "$THEMES/omatrix") == *0x1ocean* && ! -e $THEMES/omatrix-0x1ocean ]]; then
    run mv "$THEMES/omatrix" "$THEMES/omatrix-0x1ocean"
    say "renamed 0x1ocean's omatrix -> omatrix-0x1ocean"
  fi

  local entry url name
  for entry in "${OMARCHY_THEMES[@]}"; do
    url=${entry%%|*} name=${entry##*|}
    if clone_new "$url" "$THEMES/$name"; then
      record "theme:$name"
      say "$name"
    else
      skip "$name already installed"
    fi
  done

  # The RBE bundle holds four themes in subfolders; copy each out.
  local tmp="" v
  for v in "${RBE_VARIANTS[@]}"; do
    if [[ -e $THEMES/$v ]]; then skip "$v already installed"; continue; fi
    if [[ -z $tmp ]]; then
      tmp=$(mktemp -d)
      run git clone -q --depth 1 -- "$RBE_REPO" "$tmp/rbe" || { warn "could not clone $RBE_REPO"; break; }
    fi
    run cp -r "$tmp/rbe/$v" "$THEMES/$v"
    record "theme:$v"
    say "$v"
  done
  [[ -n $tmp ]] && rm -rf "$tmp"
}

# --- theme extras ---------------------------------------------------------------

om_extra_enter_the_matrix() {
  local share="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-matrix"
  if [[ -f $share/provider.json ]]; then skip "Enter The Matrix pack already installed"; return; fi
  [[ -x $THEMES/enter-the-matrix/install.sh ]] || { warn "enter-the-matrix theme missing; skipped its pack"; return; }
  say "Enter The Matrix pack (desktop rain, screensaver, lock; boot splash asks for your password)"
  run bash "$THEMES/enter-the-matrix/install.sh" || warn "Enter The Matrix pack reported an error"
  record "run:omarchy-matrix uninstall --keep-theme"
}

# tmp75's extras switch on for a theme named `matrix`; here it is `matrix-tmp75`.
om_extra_tmp75() {
  local extras="$THE_MATRIX_DATA/tmp75-extras" plugin="$PLUGINS/$USER.background"
  [[ -d $THEMES/matrix-tmp75/extras ]] || { warn "matrix-tmp75 theme missing; skipped its extras"; return; }
  if [[ -x $BIN_DIR/omarchy-matrix-idle-rain ]]; then skip "Matrix Tmp75 extras already installed"; return; fi
  if [[ -d $plugin ]] && ! grep -q 'matrix-tmp75' "$plugin/Background.qml" 2>/dev/null; then
    warn "you already have a customized $USER.background plugin; skipped Matrix Tmp75's rain so it is not overwritten"
    return
  fi
  say "Matrix Tmp75 extras (rain background, idle-fading kitty terminals)"
  run mkdir -p "$extras"
  run cp "$THEMES/matrix-tmp75/extras/"* "$extras/"
  run sed -i 's/=== "matrix"/=== "matrix-tmp75"/' "$extras/Background.qml"
  run sed -i 's/\[\[ \$name == "matrix" \]\]/[[ $name == "matrix-tmp75" ]]/' "$extras/omarchy-matrix-idle-rain"
  if ((DRY_RUN)); then run bash "$THEMES/matrix-tmp75/install-extras.sh"
  else EXTRAS_DIR="$extras" bash "$THEMES/matrix-tmp75/install-extras.sh" </dev/null | sed 's/^/    /'; fi
  record "file:$BIN_DIR/omarchy-matrix-idle-rain"
  record "tmp75-background:$plugin"
  record "autostart-line:omarchy-matrix-idle-rain"
  hyprctl reload >/dev/null 2>&1 || true
}

om_extra_omatrix() {
  local provider="${XDG_DATA_HOME:-$HOME/.local/share}/matrix-rain"
  [[ -x $THEMES/omatrix/install.sh ]] || { warn "omatrix theme missing; skipped its extras"; return; }

  # The rain itself (and `matrix`, `redpill`, `trace`) comes from matrix-rain.
  if [[ -d $provider ]]; then
    skip "matrix-rain (matrix, redpill, trace) already installed"
  else
    pac_install qt6-declarative
    say "matrix-rain: GPU rain app + terminal rain (matrix, redpill, trace)"
    clone_or_update https://github.com/leandrolalanne/matrix-rain "$SRC_DIR/matrix-rain"
    ( cd "$SRC_DIR/matrix-rain" && run ./install.sh </dev/null | sed 's/^/    /' )
    record "run:$SRC_DIR/matrix-rain/uninstall.sh"
  fi

  if [[ -e $PLUGINS/lean.omatrix ]]; then skip "Omatrix extras already installed"; return; fi
  say "Omatrix extras (live wallpapers, lock screen, font, ghostty translucency)"
  ( cd "$THEMES/omatrix" && run ./install.sh </dev/null | sed 's/^/    /' )
  # Its installer links the theme into place; when it already IS that folder,
  # `ln -sfn` drops a link to itself inside it.
  [[ -L $THEMES/omatrix/omatrix ]] && run rm "$THEMES/omatrix/omatrix"
  record "run:$THEMES/omatrix/uninstall.sh"
}

om_extra_omatrix_plugin() {
  if [[ -e $PLUGINS/io.github.0x1ocean.omatrix ]]; then skip "omatrix cmatrix-wallpaper plugin already installed"; return; fi
  say "omatrix plugin (live cmatrix wallpaper for Omatrix 0x1ocean)"
  run omarchy plugin add https://github.com/0x1ocean/omarchy-omatrix.git --enable --yes >/dev/null
  record "plugin:io.github.0x1ocean.omatrix"
}

om_extras() {
  section "Theme extras"
  om_extra_enter_the_matrix
  om_extra_omatrix
  om_extra_omatrix_plugin
  om_extra_tmp75
}

# --- tinterian's rendered video rain, as its own theme `matrix-rain` ---------

om_video_rain() {
  section "Matrix Rain video theme (renders ~15-25 min, one time)"
  if [[ -f $THEMES/matrix-rain/backgrounds/4-digital-rain-xlarge.mp4 ]]; then
    skip "Matrix Rain videos already rendered"
  else
    pac_install python-pillow ffmpeg inotify-tools noto-fonts-cjk jq
    aur_install mpvpaper beautyline || { warn "mpvpaper is needed for the video rain; skipped"; return; }
    clone_or_update https://github.com/tinterian/omarchy-matrix-rain "$TINTERIAN_SRC"
    # Upstream installs into themes/matrix, which is BVisagie's theme here.
    run sed -i 's|themes/matrix"|themes/matrix-rain"|; s|--theme-name matrix\b|--theme-name matrix-rain|g; s|\$current_theme == matrix ]]|$current_theme == matrix-rain ]]|' "$TINTERIAN_SRC/install.sh"
    run sed -i 's|themes/matrix"|themes/matrix-rain"|' "$TINTERIAN_SRC/uninstall.sh"
    run sed -i 's|\$theme_name != "matrix" ]]|$theme_name != "matrix-rain" ]]|' "$TINTERIAN_SRC/matrix-wallpaper"
    record "theme:matrix-rain"
    record "run:$TINTERIAN_SRC/uninstall.sh"
    record "dir:$TINTERIAN_SRC"
    say "rendering 4 rain videos at your screen size..."
    ( cd "$TINTERIAN_SRC" && run ./install.sh ) || { warn "Matrix Rain install failed"; return; }
  fi
  install_hook theme-set "$REPO_DIR/hooks/matrix-rain-wallpaper"
}

# --- the 3D wallpapers (asciipaper) ---------------------------------------------

om_wallpapers() {
  section "3D Matrix wallpapers (asciipaper)"
  local fresh=0
  if [[ -x $BIN_DIR/asciipaper ]]; then
    skip "asciipaper already installed"
  else
    pac_install webkitgtk-6.0 python-gobject gtk4-layer-shell
    clone_or_update https://github.com/cYoren/asciipaper "$ASCIIPAPER_SRC"
    install_file 755 "$ASCIIPAPER_SRC/asciipaper" "$BIN_DIR/asciipaper"
    run mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/asciipaper"
    run cp -r "$ASCIIPAPER_SRC/wallpapers" "${XDG_DATA_HOME:-$HOME/.local/share}/asciipaper/"
    install_file 644 "$ASCIIPAPER_SRC/asciipaper.service" "$HOME/.config/systemd/user/asciipaper.service"
    run systemctl --user daemon-reload
    record "run:$ASCIIPAPER_SRC/install.sh uninstall"
    record "dir:$ASCIIPAPER_SRC"
    fresh=1
    say "asciipaper"
  fi
  install_common_web
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
  install_hook theme-set "$REPO_DIR/hooks/asciipaper-on-top"
  say "matrix-mode 3d | intense | classic | off"
  if ((fresh)); then run "$BIN_DIR/matrix-mode" 3d; fi
}

# --- screensaver -------------------------------------------------------------------

om_screensaver() {
  section "Matrix screensaver"
  say "Omarchy's screensaver shows the Matrix rain while Omatrix or Enter The Matrix is the theme"
  if [[ -e /usr/local/bin/ttfx ]]; then
    skip "Omatrix screensaver effect already pinned"
  elif [[ -x $THEMES/omatrix/scripts/install-screensaver-effect.sh ]]; then
    if confirm "Pin the screensaver to the Matrix effect under Omatrix? (installs two small wrappers in /usr/local/bin, needs your password)"; then
      as_root "$THEMES/omatrix/scripts/install-screensaver-effect.sh" | sed 's/^/    /'
      record "root-run:$THEMES/omatrix/scripts/install-screensaver-effect.sh --remove"
    fi
  fi
  install_file 755 "$REPO_DIR/bin/matrix-screensaver" "$BIN_DIR/matrix-screensaver"
  record "file:$BIN_DIR/matrix-screensaver"
}

om_terminal() {
  section "Terminal rain"
  pac_install cmatrix
  say "cmatrix, and matrix / redpill / trace from matrix-rain"
}

install_platform() {
  have omarchy || die "Omarchy not found"
  want themes      && om_themes
  want extras      && om_extras
  want video-rain  && om_video_rain
  want wallpapers  && om_wallpapers
  want screensaver && om_screensaver
  want terminal    && om_terminal
}
