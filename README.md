# The Matrix

One installer for Matrix themes, live wallpapers and screensavers on **Linux** and **macOS**.

It collects the best Matrix themes made for [Omarchy](https://omarchy.org) and sets them up so they work together without breaking each other. It also adds two interactive 3D rain wallpapers written for this project, and on macOS runs the 3D rain as your screensaver.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/dara-greicy7/The_Matrix/main/install.sh)
```

Or clone it first:

```bash
git clone https://github.com/dara-greicy7/The_Matrix.git
cd The_Matrix
./install.sh
```

Running it again is safe: anything already installed is skipped.

## What you get

| | Omarchy | Other Linux | macOS |
|---|:-:|:-:|:-:|
| 14 Matrix desktop themes | ✓ | | |
| Theme extras: live rain, Matrix lock screens, idle terminals | ✓ | | |
| Matrix Rain video wallpaper (4 text sizes) | ✓ | | |
| Interactive 3D rain wallpaper, 2 versions | ✓ | ✓ ¹ | |
| Matrix screensaver when idle | ✓ | | ✓ ² |
| `matrix-screensaver`: 3D rain fullscreen on demand | ✓ | ✓ | ✓ |
| Terminal rain: `cmatrix` | ✓ | ✓ | ✓ |
| GPU rain app `matrix`, terminal rain `redpill`, `trace` | ✓ | ✓ ³ | |

¹ Needs a Wayland desktop with layer-shell: Hyprland, Sway, niri, river, Wayfire, labwc or KDE. Not GNOME or X11.
² Through [WebViewScreenSaver](https://github.com/liquidx/webviewscreensaver), installed with Homebrew.
³ Needs Qt 6 QML, which the installer adds on Arch, Debian/Ubuntu and Fedora.

### The 3D rain

Two versions of volumetric Matrix code rain that follow your mouse. They are plain WebGL2 pages and need no network.

- **Matrix 3D**: katakana code rain filling a 3D space around you.
- **Matrix 3D Intense**: the *Matrix Resurrections* rain as a glowing back wall, with denser, faster 3D rain in front. Both layers share the same bloom and colour palette.

| Do this | What happens |
|---|---|
| Move the cursor | The camera turns toward it |
| Click | The rain turns to flow toward the click; near the centre it comes straight at you. A pulse ripples out. |
| Double-click | Rain falls straight down again |
| Scroll | Faster or slower rain |

As a wallpaper it reacts when the cursor is over empty desktop. As a macOS screensaver, moving the mouse ends the screensaver as usual, and the camera drifts on its own.

### Themes (Omarchy)

`matrix`, `enter-the-matrix`, `omatrix`, `omatrix-0x1ocean`, `matrix-tmp75`, `the-matrix`, `matrix-trilogy`, `matrix-sakura`, `wake-up-neo`, `rbe-matrix`, `rbe-matrix-mid`, `rbe-matrix-mild`, `rbe-matrix-milder`, `matrix-rain`, plus Omatrix's four live Resurrections backgrounds. Pick one with `omarchy theme switcher`.

## Commands

```bash
matrix-mode 3d          # 3D rain wallpaper
matrix-mode intense     # Resurrections wall + 3D rain
matrix-mode classic     # Omatrix's live Resurrections rain (Omarchy)
matrix-mode off         # stop the 3D wallpaper
matrix-mode status

matrix-screensaver            # 3D rain fullscreen now (quit: Alt+F4 / Cmd+Q)
matrix-screensaver intense
matrix-screensaver --path     # the file:// URLs, e.g. for WebViewScreenSaver

matrix                  # GPU rain window: v next version, i intro, q quit
matrix list             # classic, resurrections, operator, megacity...
redpill                 # rain inside your terminal, any key quits
trace --green           # the trace program from the film
cmatrix
```

On Omarchy the idle screensaver shows the Matrix rain while **Omatrix** or **Enter The Matrix** is the active theme:

```bash
omarchy theme set omatrix
omarchy toggle screensaver     # turn the idle screensaver on or off
```

Idle timing is in `~/.config/omarchy/shell.json`, as `"idle": { "screensaver": 150, "lock": 300 }` in seconds.

## Options

```bash
./install.sh --only screensaver,terminal    # just these parts
./install.sh --skip video-rain              # everything but these
./install.sh --dry-run                      # show what would happen
./install.sh --yes                          # no questions
./install.sh --platform linux               # on Omarchy, only the generic Linux set
```

The parts are `themes`, `extras`, `video-rain`, `wallpapers`, `screensaver` and `terminal`.

The video rain renders four videos at your screen size once, which takes about 15–25 minutes. Use `--skip video-rain` if you don't want to wait.

## Uninstall

```bash
./uninstall.sh            # or: ~/.local/share/the-matrix/src/The_Matrix/uninstall.sh
./uninstall.sh --dry-run
```

The installer records each thing it adds in `~/.local/state/the-matrix/manifest`, and the uninstaller removes only those. Anything you had before is left alone. Extras are removed with their authors' own uninstallers. The theme you are currently using is kept, so switch themes first if you want it gone too.

## How it stays safe

- **No copied themes.** Every theme and extra is cloned from its author's repository at install time, so you get their latest version under their terms.
- **Only official tools touch system files.** Everything goes into your home folder except packages (pacman, apt, dnf, Homebrew) and one optional, confirmed step: Omatrix's screensaver wrapper in `/usr/local/bin`.
- **Name clashes are fixed.** Several upstream projects expect a theme folder called `matrix`. The installer gives each one its own name and patches its scripts to match, so none of them writes into another theme.
- **Your changes are kept.** An existing customized background plugin is never overwritten. Omarchy itself refuses to run Lua or terminal configs that come from downloaded themes.
- **Boot splash is opt-in.** Enter The Matrix's boot splash only happens if you choose it in its own prompt, because it rebuilds the initramfs.

## Notes

- **macOS** can't run Omarchy themes or live desktop wallpapers, because those need Linux and Wayland. You get the 3D rain as a real screensaver instead. After install, pick **WebViewScreenSaver** in System Settings › Screen Saver. If it shows the sample page, open Options and paste the address from `matrix-screensaver --path`.
- **Only one Matrix wallpaper runs at a time.** An Omatrix *live* background or the Matrix Rain video draws above the 3D wallpaper. `matrix-mode` switches between them cleanly.
- **Omatrix's installer adds a WhatsApp Web extension to Chromium.** That is the theme author's choice; its uninstaller takes it out again.

## Credits

Everything below is downloaded from its authors when you install; this repository contains none of it except the Rezmason atlas noted.

| Project | Author | License |
|---|---|---|
| [omarchy-matrix-theme](https://github.com/BVisagie/omarchy-matrix-theme) (`matrix`) | BVisagie | MIT |
| [omarchy-enter-the-matrix-theme](https://github.com/tymurbogach/omarchy-enter-the-matrix-theme) | tymurbogach | see repo |
| [omarchy-omatrix-theme](https://github.com/leandrolalanne/omarchy-omatrix-theme) (`omatrix`) | leandrolalanne | MIT |
| [matrix-rain](https://github.com/leandrolalanne/matrix-rain) (`matrix`, `redpill`, `trace`) | leandrolalanne | MIT |
| [omarchy-omatrix-theme](https://github.com/0x1ocean/omarchy-omatrix-theme) + [plugin](https://github.com/0x1ocean/omarchy-omatrix) | 0x1ocean | see repo / GPL-3.0 |
| [omarchy-matrix-theme](https://github.com/tmp75/omarchy-matrix-theme) (`matrix-tmp75`) | tmp75 | MIT |
| [omarchy-the-matrix-theme](https://github.com/CerealThriller/omarchy-the-matrix-theme) | CerealThriller | see repo |
| [omarchy-matrix-trilogy-theme](https://github.com/codeclawd/omarchy-matrix-trilogy-theme) | codeclawd | see repo |
| [omarchy-matrix-sakura-theme](https://github.com/mathiasjons82-code/omarchy-matrix-sakura-theme) | mathiasjons82-code | see repo |
| [omarchy-wake-up-neo-theme](https://github.com/nicogarazzo/omarchy-wake-up-neo-theme) | nicogarazzo | see repo |
| [omarchy-rbe-matrix-themes](https://github.com/foucist/omarchy-rbe-matrix-themes) | foucist | see repo |
| [omarchy-matrix-rain](https://github.com/tinterian/omarchy-matrix-rain) (`matrix-rain` theme) | tinterian | MIT |
| [asciipaper](https://github.com/cYoren/asciipaper) (wallpaper engine) | cYoren | MIT |
| [WebViewScreenSaver](https://github.com/liquidx/webviewscreensaver) (macOS) | liquidx | Apache-2.0 |
| [matrix](https://github.com/Rezmason/matrix): the Resurrections rain and glyph atlas in `assets/` | Rezmason | MIT, [licenses/](licenses/Rezmason-matrix-MIT.txt) |

*The Matrix* is a trademark of Warner Bros. This is a fan project with no affiliation.

The installer, `matrix-mode`, `matrix-screensaver` and the two 3D wallpapers are MIT licensed; see [LICENSE](LICENSE).
