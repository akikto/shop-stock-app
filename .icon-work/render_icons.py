#!/usr/bin/env python3
"""Render all app-icon PNG variants from the SVG sources."""
import cairosvg
from PIL import Image
import os

WORK = os.path.join(os.path.dirname(__file__), "..", ".icon-work")
OUT = os.path.join(os.path.dirname(__file__), "..", "web")
os.makedirs(os.path.join(OUT, "icons"), exist_ok=True)

def render_png(svg_path, png_path, size):
    cairosvg.svg2png(url=svg_path, write_to=png_path, output_width=size, output_height=size)
    print(f"  wrote {png_path} ({size}x{size})")

def render_transparent(svg_path, png_path, size):
    cairosvg.svg2png(url=svg_path, write_to=png_path,
                     output_width=size, output_height=size,
                     background_color=None)
    print(f"  wrote {png_path} ({size}x{size}, transparent)")

master = os.path.join(WORK, "icon-master.svg")
bg = os.path.join(WORK, "adaptive-bg.svg")
fg = os.path.join(WORK, "adaptive-fg.svg")

print("Rendering master + standard icons...")
render_png(master, os.path.join(WORK, "icon-master-1024.png"), 1024)
render_png(master, os.path.join(OUT, "icons", "Icon-192.png"), 192)
render_png(master, os.path.join(OUT, "icons", "Icon-512.png"), 512)

print("Rendering adaptive background...")
render_png(bg, os.path.join(OUT, "icons", "Icon-bg-512.png"), 512)

print("Rendering adaptive foreground (transparent)...")
render_transparent(fg, os.path.join(OUT, "icons", "Icon-fg-512.png"), 512)

print("Rendering maskable icons (background + foreground composited)...")
# Maskable icons should be the full icon (bg+fg) since Android crops them.
render_png(master, os.path.join(OUT, "icons", "Icon-maskable-192.png"), 192)
render_png(master, os.path.join(OUT, "icons", "Icon-maskable-512.png"), 512)

print("Rendering favicon (32x32)...")
render_png(master, os.path.join(OUT, "favicon.png"), 32)

print("Done.")
