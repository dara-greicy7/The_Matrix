# Shared helpers for install.sh / uninstall.sh. Sourced, not run.
# shellcheck shell=bash

THE_MATRIX_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/the-matrix"
THE_MATRIX_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/the-matrix"
MANIFEST="$THE_MATRIX_STATE/manifest"
SRC_DIR="$THE_MATRIX_DATA/src"          # upstream checkouts that need to stay on disk
BIN_DIR="$HOME/.local/bin"

DRY_RUN=${DRY_RUN:-0}
ASSUME_YES=${ASSUME_YES:-0}

if [[ -t 1 ]]; then
  G=$'\033[1;32m' D=$'\033[2m' Y=$'\033[1;33m' R=$'\033[1;31m' B=$'\033[1m' N=$'\033[0m'
else
  G="" D="" Y="" R="" B="" N=""
fi

section() { printf '\n%s== %s ==%s\n' "$G" "$*" "$N"; }
say()     { printf '  %s·%s %s\n' "$G" "$N" "$*"; }
skip()    { printf '  %s- %s%s\n' "$D" "$*" "$N"; }
warn()    { printf '  %s! %s%s\n' "$Y" "$*" "$N" >&2; }
die()     { printf '%sError:%s %s\n' "$R" "$N" "$*" >&2; exit 1; }
have()    { command -v "$1" >/dev/null 2>&1; }

# Run a command, or just print it under --dry-run.
run() {
  if ((DRY_RUN)); then
    printf '  %s[dry-run]%s %s\n' "$D" "$N" "$*"
    return 0
  fi
  "$@"
}

# Yes/no question. Defaults to yes; --yes answers yes; no terminal answers the default.
confirm() {
  local prompt=$1 default=${2:-y} reply
  ((ASSUME_YES)) && return 0
  if [[ ! -t 0 ]]; then [[ $default == y ]]; return; fi
  if [[ $default == y ]]; then read -r -p "  $prompt [Y/n] " reply || reply=""
  else read -r -p "  $prompt [y/N] " reply || reply=""; fi
  reply=${reply:-$default}
  [[ $reply =~ ^[Yy] ]]
}

# Privileged command: sudo when there is a terminal for the password, pkexec otherwise.
as_root() {
  if [[ $EUID -eq 0 ]]; then run "$@"
  elif [[ -t 0 ]] && have sudo; then run sudo "$@"
  elif have pkexec; then run pkexec "$@"
  else die "need root for: $*"; fi
}

# Record something this installer created, so uninstall.sh removes only that.
record() {
  ((DRY_RUN)) && return 0
  mkdir -p "$THE_MATRIX_STATE"
  touch "$MANIFEST"
  grep -qxF "$1" "$MANIFEST" || printf '%s\n' "$1" >>"$MANIFEST"
}
recorded() { [[ -f $MANIFEST ]] && grep -qxF "$1" "$MANIFEST"; }

# Shallow-clone a repo into a directory unless it is already there.
# Returns 0 if it cloned, 1 if the directory already existed.
clone_new() {
  local url=$1 dir=$2
  if [[ -e $dir ]]; then return 1; fi
  run mkdir -p "$(dirname "$dir")"
  run git clone -q --depth 1 -- "$url" "$dir" || die "could not clone $url"
  return 0
}

# Clone, or fast-forward an existing checkout of the same repo.
clone_or_update() {
  local url=$1 dir=$2
  if clone_new "$url" "$dir"; then return 0; fi
  if [[ -d $dir/.git ]]; then run git -C "$dir" pull -q --ff-only || warn "could not update $dir"; fi
}

git_origin() { git -C "$1" remote get-url origin 2>/dev/null || true; }

install_file() { # <mode> <src> <dest>
  run mkdir -p "$(dirname "$3")"
  run install -m "$1" "$2" "$3"
}

path_hint() {
  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) warn "$BIN_DIR is not on your PATH. Add this to your shell profile:"
       printf '      export PATH="%s:$PATH"\n' "$BIN_DIR" ;;
  esac
}

# The two 3D pages, in one place every platform can open them from.
install_common_web() {
  local web="$THE_MATRIX_DATA/web"
  run mkdir -p "$web"
  run cp "$REPO_DIR/wallpapers/matrix-3d.html" "$REPO_DIR/wallpapers/matrix-3d-intense.html" "$web/"
  record "dir:$web"
}
