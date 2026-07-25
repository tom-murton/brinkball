#!/usr/bin/env python3
"""Composite a top caption band onto a raw 1320x2868 gameplay screenshot.

Research (App Store 2025-26): captions live at the TOP of the frame (OCR-indexed
since June 2025), 3-7 words, heavy sans, light text on the game's dark bg, one
message per shot, consistent across the set. Premium ember-on-dark aesthetic.
"""
import sys
from PIL import Image, ImageDraw, ImageFont

FONT_DIR = "/Users/tommurton/GitHub/Gaming Benchmark/runs/20260716-claude-fable-5-ultra/Brinkball/Resources/Fonts"
BUNGEE = f"{FONT_DIR}/Bungee-Regular.ttf"
POPPINS = f"{FONT_DIR}/Poppins-Bold.ttf"

EMBER = (255, 158, 46)
RED = (255, 51, 61)
TEAL = (64, 230, 212)
WHITE = (245, 245, 248)
INK = (5, 5, 13)

def composite(src, dst, headline, sub=None, accent=EMBER):
    img = Image.open(src).convert("RGB")
    W, H = img.size
    band_h = int(H * 0.205)
    # Darken the caption band area with a solid ink panel so text always reads,
    # regardless of what gameplay is behind it, then a soft fade into the game.
    band = Image.new("RGB", (W, band_h), INK)
    img.paste(band, (0, 0))
    fade_h = int(H * 0.05)
    fade = Image.new("L", (1, fade_h), 0)
    for y in range(fade_h):
        fade.putpixel((0, y), int(255 * (1 - y / fade_h)))
    fade = fade.resize((W, fade_h))
    ink_panel = Image.new("RGB", (W, fade_h), INK)
    img.paste(ink_panel, (0, band_h), fade)

    draw = ImageDraw.Draw(img)
    # Accent rule under nothing; headline centered in the band.
    hl_size = 76
    font = ImageFont.truetype(BUNGEE, hl_size)
    lines = headline.split("\n")
    # Shrink to fit width.
    while True:
        widths = [draw.textlength(ln, font=font) for ln in lines]
        if max(widths) <= W * 0.88 or hl_size <= 40:
            break
        hl_size -= 2
        font = ImageFont.truetype(BUNGEE, hl_size)
    line_h = hl_size * 1.18
    total_h = line_h * len(lines)
    y = (band_h * 0.52) - total_h / 2
    for ln in lines:
        w = draw.textlength(ln, font=font)
        draw.text(((W - w) / 2, y), ln, font=font, fill=accent)
        y += line_h
    if sub:
        sf = ImageFont.truetype(POPPINS, 40)
        w = draw.textlength(sub, font=sf)
        draw.text(((W - w) / 2, band_h * 0.80), sub, font=sf, fill=WHITE)
    # Thin accent underline centered.
    ux = W * 0.5
    draw.rectangle([ux - 60, band_h * 0.12, ux + 60, band_h * 0.12 + 6], fill=accent)
    img.save(dst, "PNG")
    print(f"wrote {dst} ({headline!r})")

if __name__ == "__main__":
    src, dst, headline = sys.argv[1], sys.argv[2], sys.argv[3]
    sub = sys.argv[4] if len(sys.argv) > 4 else None
    accent = {"ember": EMBER, "red": RED, "teal": TEAL}.get(
        sys.argv[5] if len(sys.argv) > 5 else "ember", EMBER)
    composite(src, dst, headline, sub, accent)
