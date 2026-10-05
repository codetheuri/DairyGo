#!/usr/bin/env python3
"""Turns the guide screenshots into cards for WhatsApp.

Each card is 1080x1920 (portrait, like a phone): a green title band, the
phone screen with the place to tap circled and numbered, and a big caption.

    python3 docs/guides/mark.py <shots dir> <cards dir>

<shots dir> holds the screenshots and steps.json written by
mobile/test/guide/guide_screens_test.dart. Uses the app's own Inter font.
"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FONTS = ROOT / "mobile/assets/fonts"

W, H = 1080, 1920
HEADER, FOOTER = 190, 330
GREEN = (11, 94, 59)
GREEN_SOFT = (227, 243, 236)
RED = (220, 38, 38)
INK = (22, 33, 28)
GREY = (80, 96, 90)
PAPER = (246, 248, 247)


def font(weight, size):
    return ImageFont.truetype(str(FONTS / f"Inter-{weight}.ttf"), size)


def wrap(draw, text, fnt, width):
    """Splits text into lines that fit width."""
    lines, line = [], ""
    for word in text.split():
        trial = f"{line} {word}".strip()
        if draw.textlength(trial, font=fnt) <= width:
            line = trial
        else:
            lines.append(line)
            line = word
    if line:
        lines.append(line)
    return lines


def card(step, total, shots, out):
    canvas = Image.new("RGB", (W, H), PAPER)
    draw = ImageDraw.Draw(canvas)

    # Title band: the task and how far along it is.
    draw.rectangle([0, 0, W, HEADER], fill=GREEN)
    draw.text((56, 40), "DairyGo · How to", font=font("Medium", 34), fill=(190, 230, 210))
    badge = f"Step {step['step']} of {total}"
    bf = font("SemiBold", 32)
    bw = draw.textlength(badge, font=bf)
    draw.rounded_rectangle([W - 56 - bw - 40, 30, W - 56, 82], radius=26, fill=(255, 255, 255))
    draw.text((W - 56 - bw - 20, 37), badge, font=bf, fill=GREEN)
    size = 56
    while draw.textlength(step["title"], font=font("Bold", size)) > W - 112 and size > 36:
        size -= 2
    draw.text((56, 100), step["title"], font=font("Bold", size), fill="white")

    # The phone screen, scaled into the space between the bands.
    shot = Image.open(shots / step["file"]).convert("RGB")
    room_h = H - HEADER - FOOTER - 60
    scale = room_h / shot.height
    pw, ph = int(shot.width * scale), room_h
    x0, y0 = (W - pw) // 2, HEADER + 30

    # Ring and number on the spot to tap, drawn on the full-size shot so
    # the line stays crisp after scaling.
    marked = shot.copy()
    tap = step.get("tap")
    if tap:
        r = step["ratio"]
        pad = 14 * r
        box = [tap["left"] * r - pad, tap["top"] * r - pad,
               (tap["left"] + tap["width"]) * r + pad, (tap["top"] + tap["height"]) * r + pad]
        box = [max(4, box[0]), max(4, box[1]), min(shot.width - 4, box[2]), min(shot.height - 4, box[3])]
        md = ImageDraw.Draw(marked)
        md.rounded_rectangle(box, radius=int(18 * r), outline=RED, width=int(5 * r))
        cx, cy, rad = box[0], box[1], int(19 * r)
        cx, cy = max(rad + 4, cx), max(rad + 4, cy)
        md.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=RED)
        nf = font("Bold", int(24 * r))
        n = str(step["step"])
        md.text((cx - md.textlength(n, font=nf) / 2, cy - 14 * r), n, font=nf, fill="white")

    phone = marked.resize((pw, ph), Image.LANCZOS)
    # A soft shadow and a dark phone frame, so it reads as a phone.
    shadow = Image.new("RGBA", (pw + 80, ph + 80), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([40, 50, pw + 40, ph + 50], radius=44, fill=(0, 0, 0, 70))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    canvas.paste(shadow, (x0 - 40, y0 - 40), shadow)
    draw.rounded_rectangle([x0 - 14, y0 - 14, x0 + pw + 14, y0 + ph + 14], radius=46, fill=(30, 36, 34))
    mask = Image.new("L", (pw, ph), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, pw, ph], radius=34, fill=255)
    canvas.paste(phone, (x0, y0), mask)

    # Caption band.
    top = H - FOOTER
    draw.rectangle([0, top, W, H], fill="white")
    draw.rectangle([0, top, W, top + 6], fill=GREEN_SOFT)
    cf = font("SemiBold", 46)
    lines = wrap(draw, step["caption"], cf, W - 2 * 64)
    if len(lines) > 4:
        cf = font("SemiBold", 38)
        lines = wrap(draw, step["caption"], cf, W - 2 * 64)
    line_h = cf.size + 16
    y = top + (FOOTER - len(lines) * line_h) // 2 + 4
    for line in lines:
        draw.text((64, y), line, font=cf, fill=INK)
        y += line_h

    canvas.save(out, optimize=True)


def main():
    shots, cards = Path(sys.argv[1]), Path(sys.argv[2])
    cards.mkdir(parents=True, exist_ok=True)
    steps = json.loads((shots / "steps.json").read_text())
    totals = {}
    for s in steps:
        totals[s["task"]] = totals.get(s["task"], 0) + 1
    for s in steps:
        out = cards / f"{s['task']}_{s['step']}.png"
        card(s, totals[s["task"]], shots, out)
        print(out)


if __name__ == "__main__":
    main()
