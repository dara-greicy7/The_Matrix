#!/usr/bin/env python3
"""Rebuild wallpapers/matrix-3d-intense.html from its template.

The intense wallpaper embeds the Resurrections glyph atlas (assets/, from
Rezmason/matrix, MIT) as base64 so it runs from a single file with no network.
Edit wallpapers/matrix-3d-intense.template.html, then run this.
"""
import base64
from pathlib import Path

root = Path(__file__).resolve().parent.parent
template = (root / "wallpapers/matrix-3d-intense.template.html").read_text()
atlas = base64.b64encode((root / "assets/resurrections_msdf.png").read_bytes()).decode()
if "__ATLAS__" not in template:
    raise SystemExit("template has no __ATLAS__ placeholder")
(root / "wallpapers/matrix-3d-intense.html").write_text(template.replace("__ATLAS__", atlas))
print("built wallpapers/matrix-3d-intense.html")
