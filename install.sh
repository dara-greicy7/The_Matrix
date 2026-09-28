#!/usr/bin/env bash
# The Matrix: one installer for Matrix themes, wallpapers and screensavers.
#
#   ./install.sh                 install everything this machine supports
#   ./install.sh --only screensaver,terminal
#   ./install.sh --skip video-rain
#   ./install.sh --dry-run       show what would happen, change nothing
#   ./install.sh --yes           answer yes to every question
#   ./install.sh --platform linux   treat Omarchy as plain Linux (omarchy|linux|macos)
#
# Or without cloning:
#   bash <(curl -fsSL https://raw.githubusercontent.com/dara-greicy7/The_Matrix/main/install.sh)
#
# Parts: themes, extras, video-rain, wallpapers, screensaver, terminal
# Works on Omarchy (everything), other Linux, and macOS. Safe to run again:
# anything already installed is left as it is.

set -uo pipefail

REPO_URL="https://github.com/dara-greicy7/The_Matrix.git"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

# Run through curl: fetch the whole repo, then run the real installer from it.
if [[ ! -f $REPO_DIR/lib/common.sh ]]; then
  command -v git >/dev/null || { echo "The Matrix needs git. Install it and run this again." >&2; exit 1; }
  dest="${XDG_DATA_HOME:-$HOME/.local/share}/the-matrix/src/The_Matrix"
  if [[ -d $dest/.git ]]; then git -C "$dest" pull -q --ff-only || true
  else mkdir -p "$(dirname "$dest")" && git clone -q --depth 1 "$REPO_URL" "$dest" || exit 1; fi
  exec bash "$dest/install.sh" "$@"
fi

# shellcheck source=lib/common.sh
. "$REPO_DIR/lib/common.sh"

ALL_PARTS="themes extras video-rain wallpapers screensaver terminal"
ONLY="" SKIP="" PLATFORM=""

usage() { sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; }

while (($#)); do
  case $1 in
    --only) ONLY=${2:-}; shift ;;
    --only=*) ONLY=${1#*=} ;;
    --skip) SKIP=${2:-}; shift ;;
    --skip=*) SKIP=${1#*=} ;;
    --platform) PLATFORM=${2:-}; shift ;;
    --platform=*) PLATFORM=${1#*=} ;;
    -n|--dry-run) DRY_RUN=1 ;;
    -y|--yes) ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

for p in ${ONLY//,/ } ${SKIP//,/ }; do
  [[ " $ALL_PARTS " == *" $p "* ]] || die "unknown part '$p' (parts: ${ALL_PARTS// /, })"
done

want() {
  if [[ -n $ONLY && ",$ONLY," != *",$1,"* ]]; then return 1; fi
  [[ ",$SKIP," != *",$1,"* ]]
}

if [[ -z $PLATFORM ]]; then
  case $(uname -s) in
    Darwin) PLATFORM=macos ;;
    Linux)  if command -v omarchy >/dev/null 2>&1; then PLATFORM=omarchy; else PLATFORM=linux; fi ;;
    *) die "unsupported system: $(uname -s)" ;;
  esac
fi
case $PLATFORM in omarchy|linux|macos) ;; *) die "unknown platform '$PLATFORM' (omarchy, linux, macos)" ;; esac

[[ $EUID -ne 0 ]] || die "run this as your own user, not root (it asks for sudo when it needs it)"
have git || die "git is required"

printf '%s\n' "$G"
cat <<'EOF'
  ｦ ﾝ ｱ   T H E   M A T R I X   ﾊ ﾐ ﾋ
EOF
printf '%s' "$N"
case $PLATFORM in
  omarchy) say "Omarchy detected: themes, extras, video rain, 3D wallpapers, screensavers, terminal rain" ;;
  linux)   say "Linux detected: terminal rain, 3D screensaver, 3D wallpaper (Wayland layer-shell desktops)" ;;
  macos)   say "macOS detected: terminal rain, 3D rain as your screensaver" ;;
esac
((DRY_RUN)) && say "dry run: nothing will be changed"
if want video-rain && [[ $PLATFORM == omarchy ]]; then
  say "the video rain renders 4 videos once (~15-25 min); skip it with --skip video-rain"
fi
confirm "Continue?" || exit 0

# shellcheck source=/dev/null
. "$REPO_DIR/lib/$PLATFORM.sh"
install_platform

section "Done"
case $PLATFORM in
  omarchy) cat <<EOF
  Themes        omarchy theme switcher       (or: omarchy theme set omatrix)
  Wallpapers    matrix-mode 3d | intense | classic | off | status
  Screensaver   set the Omatrix or Enter The Matrix theme; it starts when idle
                matrix-screensaver [3d|intense]   the 3D rain fullscreen, any time
  Terminal      matrix   redpill   trace --green   cmatrix
EOF
  ;;
  linux) cat <<EOF
  Screensaver   matrix-screensaver [3d|intense]
  Wallpaper     matrix-mode 3d | intense | off | status   (Wayland layer-shell desktops)
  Terminal      cmatrix   matrix   redpill   (matrix/redpill when Qt 6 QML is available)
EOF
  ;;
  macos) cat <<EOF
  Screensaver   System Settings > Screen Saver > WebViewScreenSaver
                matrix-screensaver [3d|intense]   fullscreen in your browser, any time
  Terminal      cmatrix
EOF
  ;;
esac
say "Uninstall with: $REPO_DIR/uninstall.sh"
path_hint
