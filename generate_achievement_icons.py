import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUTPUT_DIR = r"d:\Mobile Apps\Maths Puzzul Game\assets\images\achievements"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Try to find a good Windows font
FONT_BOLD = None
FONT_REGULAR = None
candidates_bold = ["C:/Windows/Fonts/segoeuib.ttf", "C:/Windows/Fonts/arialbd.ttf", "C:/Windows/Fonts/calibrib.ttf"]
candidates_reg = ["C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/arial.ttf", "C:/Windows/Fonts/calibri.ttf"]

for p in candidates_bold:
    if os.path.exists(p):
        FONT_BOLD = p
        break

for p in candidates_reg:
    if os.path.exists(p):
        FONT_REGULAR = p
        break

def draw_star(draw, cx, cy, r_outer, r_inner, fill_color, outline_color=None, width=1):
    points = []
    for i in range(10):
        r = r_outer if i % 2 == 0 else r_inner
        angle = -math.pi / 2 + i * (math.pi / 5)
        points.append((cx + r * math.cos(angle), cy + r * math.sin(angle)))
    draw.polygon(points, fill=fill_color, outline=outline_color, width=width)

def draw_flame(draw, cx, cy, scale, fill_colors):
    # Layered flame shapes
    for (s_f, fill) in fill_colors:
        pts = [
            (cx, cy - 120 * scale * s_f),
            (cx + 40 * scale * s_f, cy - 60 * scale * s_f),
            (cx + 70 * scale * s_f, cy + 20 * scale * s_f),
            (cx + 50 * scale * s_f, cy + 80 * scale * s_f),
            (cx, cy + 100 * scale * s_f),
            (cx - 50 * scale * s_f, cy + 80 * scale * s_f),
            (cx - 70 * scale * s_f, cy + 20 * scale * s_f),
            (cx - 40 * scale * s_f, cy - 60 * scale * s_f),
        ]
        draw.polygon(pts, fill=fill)

def create_base_badge(bg_gradient_colors, rim_color, inner_rim):
    size = 512
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx, cy = size // 2, size // 2
    r_outer = 236

    # Soft outer drop shadow
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.ellipse([cx - r_outer + 4, cy - r_outer + 12, cx + r_outer - 4, cy + r_outer + 12], fill=(0, 0, 0, 110))
    shadow = shadow.filter(ImageFilter.GaussianBlur(14))
    img.paste(shadow, (0, 0), shadow)

    # Outer golden ring
    draw.ellipse([cx - r_outer, cy - r_outer, cx + r_outer, cy + r_outer], fill=rim_color)
    # Inner border
    draw.ellipse([cx - r_outer + 12, cy - r_outer + 12, cx + r_outer - 12, cy + r_outer - 12], fill=inner_rim)

    # Core background circular gradient approximation
    core_r = r_outer - 20
    c_start, c_end = bg_gradient_colors
    for i in range(core_r, 0, -2):
        t = (core_r - i) / core_r
        # Interpolate
        r = int(c_start[0] * (1 - t) + c_end[0] * t)
        g = int(c_start[1] * (1 - t) + c_end[1] * t)
        b = int(c_start[2] * (1 - t) + c_end[2] * t)
        draw.ellipse([cx - i, cy - i, cx + i, cy + i], fill=(r, g, b, 255))

    return img

def create_badge(filename, title, subtitle, bg_colors, rim_color, inner_rim, icon_type):
    img = create_base_badge(bg_colors, rim_color, inner_rim)
    draw = ImageDraw.Draw(img)
    cx, cy = 256, 256

    font_title = ImageFont.truetype(FONT_BOLD, 38)
    font_sub = ImageFont.truetype(FONT_REGULAR, 26)
    font_big = ImageFont.truetype(FONT_BOLD, 92)
    font_huge = ImageFont.truetype(FONT_BOLD, 120)

    # Draw specific icon/graphics
    if icon_type == "math_50":
        draw.text((cx, cy - 40), "+ ×", font=font_big, fill=(255, 235, 170), anchor="mm")
        draw.text((cx, cy + 45), "÷ −", font=font_big, fill=(255, 235, 170), anchor="mm")
    elif icon_type == "math_250":
        draw.text((cx, cy - 35), "∑ π", font=font_big, fill=(255, 245, 190), anchor="mm")
        draw.text((cx, cy + 45), "250", font=font_big, fill=(255, 215, 0), anchor="mm")
    elif icon_type == "math_1000":
        draw.text((cx, cy - 45), "★", font=font_huge, fill=(255, 215, 0), anchor="mm")
        draw.text((cx, cy + 45), "1000", font=font_big, fill=(255, 245, 220), anchor="mm")
    elif icon_type == "star_1":
        draw_star(draw, cx, cy, 95, 45, (255, 215, 0), (255, 245, 180), 4)
    elif icon_type == "star_2":
        draw_star(draw, cx - 48, cy, 75, 35, (255, 215, 0), (255, 245, 180), 3)
        draw_star(draw, cx + 48, cy, 75, 35, (255, 215, 0), (255, 245, 180), 3)
    elif icon_type == "star_3":
        draw_star(draw, cx - 75, cy + 20, 60, 28, (255, 215, 0), (255, 245, 180), 3)
        draw_star(draw, cx, cy - 30, 85, 40, (255, 235, 80), (255, 255, 220), 4)
        draw_star(draw, cx + 75, cy + 20, 60, 28, (255, 215, 0), (255, 245, 180), 3)
    elif icon_type == "bulb":
        # Draw glowing bulb
        draw.ellipse([cx - 50, cy - 80, cx + 50, cy + 10], fill=(255, 235, 59))
        draw.rectangle([cx - 30, cy + 5, cx + 30, cy + 45], fill=(200, 200, 210))
        draw.rectangle([cx - 20, cy + 45, cx + 20, cy + 60], fill=(160, 160, 170))
        draw.arc([cx - 70, cy - 100, cx + 70, cy + 30], 200, 340, fill=(255, 255, 200), width=6)
    elif icon_type == "flame_1":
        flame_colors = [
            (1.0, (230, 81, 0)),
            (0.8, (255, 152, 0)),
            (0.5, (255, 235, 59)),
        ]
        draw_flame(draw, cx, cy - 10, 1.0, flame_colors)
    elif icon_type == "flame_2":
        flame_colors = [
            (1.2, (183, 28, 28)),
            (0.95, (230, 81, 0)),
            (0.7, (255, 152, 0)),
            (0.4, (255, 235, 59)),
        ]
        draw_flame(draw, cx, cy - 15, 1.1, flame_colors)

    # Subtitle / banner bar at bottom
    draw.rectangle([cx - 150, cy + 135, cx + 150, cy + 185], fill=(20, 20, 25, 220))
    draw.text((cx, cy + 158), title.upper(), font=font_sub, fill=(255, 255, 255), anchor="mm")

    full_path = os.path.join(OUTPUT_DIR, filename)
    img.save(full_path, "PNG")
    print(f"Generated {full_path}")

# Golden rim colors
GOLD_OUTER = (212, 175, 55)
GOLD_INNER = (255, 223, 100)
BRONZE_OUTER = (176, 120, 60)
BRONZE_INNER = (218, 165, 95)
SILVER_OUTER = (180, 190, 200)
SILVER_INNER = (225, 235, 245)

achievements = [
    ("math_apprentice.png", "50 Solved", "Math Apprentice", ((30, 60, 90), (15, 30, 50)), BRONZE_OUTER, BRONZE_INNER, "math_50"),
    ("arithmetic_wizard.png", "250 Solved", "Arithmetic Wizard", ((20, 75, 60), (10, 40, 30)), SILVER_OUTER, SILVER_INNER, "math_250"),
    ("crossmath_legend.png", "1000 Solved", "Crossmath Legend", ((70, 30, 90), (35, 15, 50)), GOLD_OUTER, GOLD_INNER, "math_1000"),
    ("beginner.png", "10 Levels", "Beginner", ((40, 70, 45), (20, 40, 25)), BRONZE_OUTER, BRONZE_INNER, "star_1"),
    ("explorer.png", "50 Levels", "Explorer", ((25, 60, 85), (15, 35, 50)), SILVER_OUTER, SILVER_INNER, "star_2"),
    ("conqueror.png", "150 Levels", "Conqueror", ((90, 55, 20), (50, 28, 10)), GOLD_OUTER, GOLD_INNER, "star_3"),
    ("need_a_hand.png", "20 Hints", "Need a Hand?", ((80, 70, 20), (45, 40, 10)), GOLD_OUTER, GOLD_INNER, "bulb"),
    ("warming_up.png", "3-Day Streak", "Warming Up", ((90, 45, 15), (50, 25, 10)), BRONZE_OUTER, BRONZE_INNER, "flame_1"),
    ("on_fire.png", "7-Day Streak", "On Fire", ((100, 25, 15), (55, 12, 8)), GOLD_OUTER, GOLD_INNER, "flame_2"),
]

for filename, title, desc, bg, rim, inner, icon in achievements:
    create_badge(filename, title, desc, bg, rim, inner, icon)

print("ALL 9 ICONS GENERATED SUCCESSFULLY!")
