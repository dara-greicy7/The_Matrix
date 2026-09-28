#!/usr/bin/env bash
# Remove what The Matrix installer added, and nothing else.
#
#   ./uninstall.sh            undo everything recorded by install.sh
#   ./uninstall.sh --dry-run  show what would be removed
#   ./uninstall.sh --yes      no questions
#
# install.sh records each thing it creates in ~/.local/state/the-matrix/manifest.
# Anything that was already on the machine before is not in it and is left alone.
# Upstream extras are removed with their own uninstallers.

set -uo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$REPO_DIR/lib/common.sh"

while (($#)); do
  case $1 in
    -n|--dry-run) DRY_RUN=1 ;;
    -y|--yes) ASSUME_YES=1 ;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

[[ -s $MANIFEST ]] || { say "nothing to remove: no install record at $MANIFEST"; exit 0; }

section "The Matrix uninstall"
say "$(wc -l <"$MANIFEST" | tr -d ' ') recorded items"
confirm "Remove them?" n || exit 0

THEMES="$HOME/.config/omarchy/themes"
current_theme=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null || true)
kept="" kept_n=0

# Newest first: extras recorded after their theme are undone before it goes.
while IFS= read -r entry; do
  kind=${entry%%:*} arg=${entry#*:}
  case $kind in
    run)
      say "running: $arg"
      run bash -c "$arg" </dev/null 2>&1 | sed 's/^/    /' ;;
    root-run)
      say "running (needs your password): $arg"
      # shellcheck disable=SC2086
      as_root $arg 2>&1 | sed 's/^/    /' ;;
    theme)
      if [[ $arg == "$current_theme" ]]; then
        warn "theme $arg is in use; switch theme and run this again to remove it"
        kept+="$entry"$'\n'; kept_n=$((kept_n + 1)); continue
      fi
      [[ -e $THEMES/$arg ]] && { run rm -rf "${THEMES:?}/$arg"; say "theme $arg"; } ;;
    hook)
      run rm -f "$HOME/.config/omarchy/hooks/${arg%%/*}.d/${arg#*/}" && say "hook $arg" ;;
    plugin)
      run omarchy plugin remove "$arg" --yes >/dev/null 2>&1 && say "plugin $arg" ;;
    tmp75-background)
      # tmp75 swapped the shell background for a clone; give back the built-in one.
      if [[ -d $arg ]] && grep -q 'matrix-tmp75' "$arg/Background.qml" 2>/dev/null; then
        run omarchy plugin enable omarchy.background >/dev/null 2>&1
        run omarchy plugin remove "$(basename "$arg")" --yes >/dev/null 2>&1 || run rm -rf "$arg"
        say "restored the built-in background plugin"
      fi ;;
    autostart-line)
      f="$HOME/.config/hypr/autostart.lua"
      if [[ -f $f ]] && grep -q "$arg" "$f"; then
        run sed -i "/Matrix theme: fade idle kitty/d; /rain wallpaper shows through empty cells/d; /$arg/d" "$f"
        say "removed $arg from autostart.lua"
      fi ;;
    cask)
      have brew && run brew uninstall --cask "$arg" && say "cask $arg" ;;
    file)
      [[ -e $arg ]] && { run rm -f "$arg"; say "$arg"; } ;;
    dir)
      [[ -e $arg ]] && { run rm -rf "$arg"; say "$arg"; } ;;
    *) warn "unknown record: $entry" ;;
  esac
done < <(awk '{ line[NR] = $0 } END { for (i = NR; i > 0; i--) print line[i] }' "$MANIFEST")

if ((DRY_RUN)); then exit 0; fi
if ((kept_n)); then
  printf '%s' "$kept" >"$MANIFEST"
  warn "kept $kept_n item(s) in use; the rest is removed"
else
  rm -f "$MANIFEST"
fi
command -v hyprctl >/dev/null && hyprctl reload >/dev/null 2>&1
section "Done"
