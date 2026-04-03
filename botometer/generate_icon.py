#!/usr/bin/env python3
"""Generate monochrome speedometer app icon for GlassUsage at all required macOS sizes."""

import math
import os
from PIL import Image, ImageDraw

ICON_DIR = "GlassUsage/Assets.xcassets/AppIcon.appiconset"
GAUGE_DIR = "Shared/Assets.xcassets/GaugeIcon.imageset"
MENUBAR_DIR = "GlassUsage/Assets.xcassets/MenuBarIcon.imageset"

SIZES = [
    ("icon_16x16.png",    16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png",    32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png",  128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png",  256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png",  512),
    ("icon_512x512@2x.png", 1024),
]

def draw_icon(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    pad = size * 0.04
    r_bg = size * 0.22  # corner radius for background

    # Dark rounded-rect background
    d.rounded_rectangle([pad, pad, size - pad, size - pad],
                        radius=r_bg, fill=(20, 20, 20, 255))

    # Subtle inner glow ring
    glow_w = max(1, size * 0.012)
    d.rounded_rectangle([pad + glow_w, pad + glow_w,
                         size - pad - glow_w, size - pad - glow_w],
                        radius=r_bg * 0.88,
                        outline=(80, 80, 80, 120),
                        width=max(1, int(glow_w)))

    cx = size / 2
    # Shift dial centre slightly upward so needle has room at bottom
    cy = size * 0.54

    # Dial spans 210° (from ~195° to ~345° in standard math coords,
    # but PIL angles: 0=3-o'clock, clockwise positive)
    # We want: left end = ~215°, right end = ~325° (PIL coords, clockwise from 3-o'clock)
    START_DEG = 215   # PIL: measured clockwise from 3-o'clock
    END_DEG   = 325
    SWEEP     = END_DEG - START_DEG   # 110° — leaves a gap at the bottom

    outer_r = size * 0.36
    inner_r = size * 0.28
    arc_w   = max(1, int(size * 0.045))

    # Background arc (dim)
    d.arc([cx - outer_r, cy - outer_r, cx + outer_r, cy + outer_r],
          start=START_DEG, end=END_DEG,
          fill=(60, 60, 60, 255), width=arc_w)

    # Filled arc up to ~65% (representing some usage level)
    fill_pct  = 0.62
    fill_end  = START_DEG + SWEEP * fill_pct
    arc_fill  = (220, 220, 220, 255)
    d.arc([cx - outer_r, cy - outer_r, cx + outer_r, cy + outer_r],
          start=START_DEG, end=fill_end,
          fill=arc_fill, width=arc_w)

    # Tick marks
    tick_count = 9
    for i in range(tick_count + 1):
        t        = i / tick_count
        angle_d  = START_DEG + SWEEP * t
        angle_r  = math.radians(angle_d)
        is_major = (i % 2 == 0)
        t_outer  = outer_r + size * 0.015
        t_inner  = t_outer - (size * 0.055 if is_major else size * 0.032)
        t_w      = max(1, int(size * (0.022 if is_major else 0.014)))
        x1 = cx + t_outer * math.cos(angle_r)
        y1 = cy + t_outer * math.sin(angle_r)
        x2 = cx + t_inner * math.cos(angle_r)
        y2 = cy + t_inner * math.sin(angle_r)
        brightness = 200 if is_major else 120
        d.line([x1, y1, x2, y2], fill=(brightness, brightness, brightness, 255), width=t_w)

    # Needle — pointing at fill_pct position
    needle_angle_r = math.radians(START_DEG + SWEEP * fill_pct)
    needle_len = outer_r * 0.82
    tail_len   = outer_r * 0.18
    nx = cx + needle_len * math.cos(needle_angle_r)
    ny = cy + needle_len * math.sin(needle_angle_r)
    tx = cx - tail_len * math.cos(needle_angle_r)
    ty = cy - tail_len * math.sin(needle_angle_r)
    needle_w = max(1, int(size * 0.022))
    d.line([tx, ty, nx, ny], fill=(255, 255, 255, 255), width=needle_w)

    # Needle pivot dot
    pivot_r = size * 0.038
    d.ellipse([cx - pivot_r, cy - pivot_r, cx + pivot_r, cy + pivot_r],
              fill=(255, 255, 255, 255))
    inner_pivot = pivot_r * 0.5
    d.ellipse([cx - inner_pivot, cy - inner_pivot, cx + inner_pivot, cy + inner_pivot],
              fill=(20, 20, 20, 255))

    # Small "AI" label below pivot — only at larger sizes
    if size >= 128:
        label_y = cy + outer_r * 0.38
        dot_r   = max(1, size * 0.016)
        spacing = size * 0.06
        # Two dots = simple AI-ish motif (minimal, readable at small sizes)
        for dx in [-spacing * 0.5, spacing * 0.5]:
            d.ellipse([cx + dx - dot_r, label_y - dot_r,
                       cx + dx + dot_r, label_y + dot_r],
                      fill=(160, 160, 160, 255))

    return img


def draw_gauge_template(size: int) -> Image.Image:
    """Gauge-only icon: transparent background, white shapes. Used as template image."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    cx = size / 2
    cy = size * 0.54

    START_DEG = 215
    END_DEG   = 325
    SWEEP     = END_DEG - START_DEG

    outer_r = size * 0.42
    arc_w   = max(1, int(size * 0.055))

    # Background arc (dim white)
    d.arc([cx - outer_r, cy - outer_r, cx + outer_r, cy + outer_r],
          start=START_DEG, end=END_DEG,
          fill=(255, 255, 255, 80), width=arc_w)

    # Filled arc at ~62%
    fill_pct = 0.62
    fill_end = START_DEG + SWEEP * fill_pct
    d.arc([cx - outer_r, cy - outer_r, cx + outer_r, cy + outer_r],
          start=START_DEG, end=fill_end,
          fill=(255, 255, 255, 255), width=arc_w)

    # Tick marks
    tick_count = 9
    for i in range(tick_count + 1):
        t        = i / tick_count
        angle_d  = START_DEG + SWEEP * t
        angle_r  = math.radians(angle_d)
        is_major = (i % 2 == 0)
        t_outer  = outer_r + size * 0.01
        t_inner  = t_outer - (size * 0.06 if is_major else size * 0.035)
        t_w      = max(1, int(size * (0.025 if is_major else 0.016)))
        x1 = cx + t_outer * math.cos(angle_r)
        y1 = cy + t_outer * math.sin(angle_r)
        x2 = cx + t_inner * math.cos(angle_r)
        y2 = cy + t_inner * math.sin(angle_r)
        alpha = 255 if is_major else 160
        d.line([x1, y1, x2, y2], fill=(255, 255, 255, alpha), width=t_w)

    # Needle
    needle_angle_r = math.radians(START_DEG + SWEEP * fill_pct)
    needle_len = outer_r * 0.80
    tail_len   = outer_r * 0.18
    nx = cx + needle_len * math.cos(needle_angle_r)
    ny = cy + needle_len * math.sin(needle_angle_r)
    tx = cx - tail_len * math.cos(needle_angle_r)
    ty = cy - tail_len * math.sin(needle_angle_r)
    d.line([tx, ty, nx, ny], fill=(255, 255, 255, 255), width=max(1, int(size * 0.025)))

    # Pivot
    pivot_r = size * 0.042
    d.ellipse([cx - pivot_r, cy - pivot_r, cx + pivot_r, cy + pivot_r],
              fill=(255, 255, 255, 255))
    inner_p = pivot_r * 0.45
    d.ellipse([cx - inner_p, cy - inner_p, cx + inner_p, cy + inner_p],
              fill=(0, 0, 0, 0))

    return img


def draw_menubar_icon(size: int) -> Image.Image:
    """
    Ultra-minimal menu bar icon: black shapes on transparent.
    At 18pt rendering: just a bold arc + needle. No ticks, no details.
    macOS renders template images — black becomes white/black to match menu bar.
    """
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    cx = size / 2
    cy = size * 0.56   # shift down slightly so arc has room at top

    START_DEG = 210
    END_DEG   = 330
    SWEEP     = END_DEG - START_DEG
    fill_pct  = 0.62

    r = size * 0.38
    arc_w = max(2, int(size * 0.13))  # thick stroke — readable at small sizes

    # Single bold arc (full range, solid black)
    d.arc([cx - r, cy - r, cx + r, cy + r],
          start=START_DEG, end=END_DEG,
          fill=(0, 0, 0, 255), width=arc_w)

    # Needle — thick enough to see at 18pt
    angle_r = math.radians(START_DEG + SWEEP * fill_pct)
    nlen = r * 0.78
    tlen = r * 0.22
    d.line([
        cx - tlen * math.cos(angle_r),
        cy - tlen * math.sin(angle_r),
        cx + nlen * math.cos(angle_r),
        cy + nlen * math.sin(angle_r),
    ], fill=(0, 0, 0, 255), width=max(2, int(size * 0.1)))

    # Pivot dot
    pr = max(2, int(size * 0.1))
    d.ellipse([cx - pr, cy - pr, cx + pr, cy + pr], fill=(0, 0, 0, 255))

    return img


def main():
    os.makedirs(ICON_DIR, exist_ok=True)
    for filename, size in SIZES:
        img  = draw_icon(size)
        path = os.path.join(ICON_DIR, filename)
        img.save(path, "PNG")
        print(f"  {path}  ({size}x{size})")

    # Update Contents.json with filenames
    entries = []
    for (filename, size), (idiom_size, scale) in zip(SIZES, [
        ("16x16", "1x"), ("16x16", "2x"),
        ("32x32", "1x"), ("32x32", "2x"),
        ("128x128", "1x"), ("128x128", "2x"),
        ("256x256", "1x"), ("256x256", "2x"),
        ("512x512", "1x"), ("512x512", "2x"),
    ]):
        entries.append(
            f'    {{\n'
            f'      "filename" : "{filename}",\n'
            f'      "idiom" : "mac",\n'
            f'      "scale" : "{scale}",\n'
            f'      "size" : "{idiom_size}"\n'
            f'    }}'
        )

    contents = (
        '{\n'
        '  "images" : [\n'
        + ',\n'.join(entries) + '\n'
        '  ],\n'
        '  "info" : {\n'
        '    "author" : "xcode",\n'
        '    "version" : 1\n'
        '  }\n'
        '}\n'
    )
    with open(os.path.join(ICON_DIR, "Contents.json"), "w") as f:
        f.write(contents)
    print("  Contents.json updated")
    print("Done.")

    # Generate gauge template icons for menu bar / widget header
    os.makedirs(GAUGE_DIR, exist_ok=True)
    for name, sz in [("gauge_icon.png", 64), ("gauge_icon@2x.png", 128)]:
        img  = draw_gauge_template(sz)
        path = os.path.join(GAUGE_DIR, name)
        img.save(path, "PNG")
        print(f"  {path}  ({sz}x{sz})")

    gauge_contents = """{
  "images" : [
    {
      "filename" : "gauge_icon.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "gauge_icon@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "template-rendering-intent" : "template"
  }
}
"""
    # Also write the xcassets Contents.json
    assets_dir = os.path.dirname(GAUGE_DIR)
    with open(os.path.join(assets_dir, "Contents.json"), "w") as f:
        f.write('{\n  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}\n')
    with open(os.path.join(GAUGE_DIR, "Contents.json"), "w") as f:
        f.write(gauge_contents)
    print("  Shared/Assets.xcassets written")

    # Menu bar icon — 18x18 @1x and 36x36 @2x, black on transparent (template)
    os.makedirs(MENUBAR_DIR, exist_ok=True)
    for name, sz in [("menubar_icon.png", 18), ("menubar_icon@2x.png", 36)]:
        img  = draw_menubar_icon(sz)
        path = os.path.join(MENUBAR_DIR, name)
        img.save(path, "PNG")
        print(f"  {path}  ({sz}x{sz})")

    menubar_contents = """{
  "images" : [
    {
      "filename" : "menubar_icon.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "menubar_icon@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "template-rendering-intent" : "template"
  }
}
"""
    with open(os.path.join(MENUBAR_DIR, "Contents.json"), "w") as f:
        f.write(menubar_contents)
    print("  MenuBarIcon written")


if __name__ == "__main__":
    main()
