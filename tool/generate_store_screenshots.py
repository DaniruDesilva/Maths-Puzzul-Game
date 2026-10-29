import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUTPUT_DIR = r"assets/images/store/screenshots"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# 1080 x 1920 Google Play Standard
W, H = 1080, 1920

# Fonts
FONT_BOLD = None
FONT_REGULAR = None
FONT_SEMIBOLD = None
for p in ["C:/Windows/Fonts/segoeuib.ttf", "C:/Windows/Fonts/arialbd.ttf"]:
    if os.path.exists(p):
        FONT_BOLD = p
        break

for p in ["C:/Windows/Fonts/segoeui.ttf", "C:/Windows/Fonts/arial.ttf"]:
    if os.path.exists(p):
        FONT_REGULAR = p
        break

def get_font(size, bold=True):
    path = FONT_BOLD if bold else FONT_REGULAR
    try:
        return ImageFont.truetype(path, size)
    except:
        return ImageFont.load_default()

def draw_vertical_gradient(draw, width, height, color_top, color_bottom):
    for y in range(height):
        t = y / float(height)
        r = int(color_top[0] * (1 - t) + color_bottom[0] * t)
        g = int(color_top[1] * (1 - t) + color_bottom[1] * t)
        b = int(color_top[2] * (1 - t) + color_bottom[2] * t)
        draw.line([(0, y), (width, y)], fill=(r, g, b))

def draw_rounded_card(img, bbox, radius, fill_color, border_color=None, border_width=0, shadow_blur=18, shadow_offset=(0, 12)):
    x0, y0, x1, y1 = bbox
    w, h = x1 - x0, y1 - y0
    
    # Shadow
    if shadow_blur > 0:
        shadow = Image.new("RGBA", (w + shadow_blur * 4, h + shadow_blur * 4), (0, 0, 0, 0))
        s_draw = ImageDraw.Draw(shadow)
        s_draw.rounded_rectangle([shadow_blur * 2, shadow_blur * 2, shadow_blur * 2 + w, shadow_blur * 2 + h],
                                radius=radius, fill=(0, 0, 0, 100))
        shadow = shadow.filter(ImageFilter.GaussianBlur(shadow_blur))
        sx = x0 - shadow_blur * 2 + shadow_offset[0]
        sy = y0 - shadow_blur * 2 + shadow_offset[1]
        img.paste(shadow, (sx, sy), shadow)
        
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle(bbox, radius=radius, fill=fill_color, outline=border_color, width=border_width)

def draw_header_pill(draw, cx, cy, text, bg_color, text_color):
    font = get_font(32, bold=True)
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    px, py = 28, 12
    rect = [cx - tw//2 - px, cy - th//2 - py, cx + tw//2 + px, cy + th//2 + py]
    draw.rounded_rectangle(rect, radius=24, fill=bg_color)
    draw.text((cx, cy - 2), text, font=font, fill=text_color, anchor="mm")

def draw_titles(draw, title, subtitle, pill_text=None, pill_bg=(255, 215, 0), pill_fg=(30, 20, 10)):
    curr_y = 110
    if pill_text:
        draw_header_pill(draw, W // 2, curr_y, pill_text, pill_bg, pill_fg)
        curr_y += 85
    else:
        curr_y += 30

    font_title = get_font(58, bold=True)
    font_sub = get_font(34, bold=False)

    # Title with subtle shadow
    draw.text((W // 2 + 2, curr_y + 2), title, font=font_title, fill=(0, 0, 0, 160), anchor="mm")
    draw.text((W // 2, curr_y), title, font=font_title, fill=(255, 255, 255), anchor="mm")

    # Subtitle
    curr_y += 68
    draw.text((W // 2, curr_y), subtitle, font=font_sub, fill=(240, 230, 210), anchor="mm")

def draw_phone_frame(img, px, py, pw, ph, bg_color=(27, 38, 32)):
    # Outer device frame (bezel)
    draw_rounded_card(img, (px, py, px + pw, py + ph), radius=56, fill_color=(20, 24, 22), 
                      border_color=(70, 80, 75), border_width=4, shadow_blur=28, shadow_offset=(0, 18))
    # Screen glass area
    screen_rect = (px + 16, py + 16, px + pw - 16, py + ph - 16)
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle(screen_rect, radius=44, fill=bg_color)
    
    # Camera notch/island pill at top
    notch_w, notch_h = 140, 28
    notch_rect = (px + pw // 2 - notch_w // 2, py + 26, px + pw // 2 + notch_w // 2, py + 26 + notch_h)
    draw.rounded_rectangle(notch_rect, radius=14, fill=(10, 12, 11))
    
    return screen_rect

def safe_load_image(path, resize=None):
    if os.path.exists(path):
        im = Image.open(path).convert("RGBA")
        if resize:
            im = im.resize(resize, Image.Resampling.LANCZOS)
        return im
    return None

def paste_centered(dst, src, cx, cy):
    if src:
        w, h = src.size
        dst.paste(src, (cx - w // 2, cy - h // 2), src)

# ==============================================================================
# SCREENSHOT 1: HERO HOOK (CROSSMATH MEETS COZY VILLAGE)
# ==============================================================================
def generate_screenshot_1():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    draw_vertical_gradient(draw, W, H, (18, 55, 42), (8, 24, 18))

    draw_titles(draw, "CROSSMATH MEETS COZY VILLAGE", "Solve Math Puzzles & Build Your Dream Haven", pill_text="✨ NEW HYBRID PUZZLE")

    phone_x, phone_y, phone_w, phone_h = 100, 390, 880, 1470
    s_x0, s_y0, s_x1, s_y1 = draw_phone_frame(img, phone_x, phone_y, phone_w, phone_h, bg_color=(24, 34, 28))

    # In Phone: Top Half = Math Crossword Board
    draw = ImageDraw.Draw(img)
    board_rect = (s_x0 + 40, s_y0 + 90, s_x1 - 40, s_y0 + 640)
    draw_rounded_card(img, board_rect, radius=32, fill_color=(45, 34, 24), border_color=(120, 95, 65), border_width=3, shadow_blur=14)

    # Draw neat grid inside board
    grid_cells = [
        ("7", True, 0, 0), ("+", False, 1, 0), ("5", True, 2, 0), ("=", False, 3, 0), ("12", True, 4, 0),
        ("÷", False, 2, 1),
        ("3", True, 0, 2), ("×", False, 1, 2), ("2", True, 2, 2), ("=", False, 3, 2), ("6", True, 4, 2),
    ]
    start_gx = s_x0 + 85
    start_gy = s_y0 + 130
    cell_size = 110
    gap = 20
    font_num = get_font(52, bold=True)
    font_op = get_font(56, bold=True)

    for val, is_num, col, row in grid_cells:
        cx = start_gx + col * (cell_size + gap)
        cy = start_gy + row * (cell_size + gap)
        if is_num:
            # Wooden number tile
            draw_rounded_card(img, (cx, cy, cx + cell_size, cy + cell_size), radius=20,
                              fill_color=(225, 185, 125), border_color=(255, 230, 180), border_width=2, shadow_blur=6)
            draw.text((cx + cell_size // 2, cy + cell_size // 2 - 4), val, font=font_num, fill=(60, 40, 20), anchor="mm")
        else:
            draw.text((cx + cell_size // 2, cy + cell_size // 2 - 4), val, font=font_op, fill=(245, 215, 140), anchor="mm")

    # In Phone: Bottom Half = Village Island
    island = safe_load_image("assets/images/village/meadow/island_bg.webp", resize=(780, 500))
    if island:
        img.paste(island, (s_x0 + 35, s_y0 + 680), island)

    cottage = safe_load_image("assets/images/village/meadow/cottage_stage3.webp", resize=(240, 240))
    if cottage:
        img.paste(cottage, (s_x0 + 120, s_y0 + 810), cottage)

    windmill = safe_load_image("assets/images/village/meadow/windmill_stage3.webp", resize=(220, 270))
    if windmill:
        img.paste(windmill, (s_x0 + 480, s_y0 + 760), windmill)

    # Mascots on screen
    owl = safe_load_image("assets/images/village/villagers/owl_hd.webp", resize=(220, 220))
    if owl:
        img.paste(owl, (s_x0 + 60, s_y0 + 1150), owl)

    bunny = safe_load_image("assets/images/village/villagers/bunny_hd.webp", resize=(200, 200))
    if bunny:
        img.paste(bunny, (s_x1 - 250, s_y0 + 1170), bunny)

    # Bottom Banner inside phone: "Solve Equations ➔ Upgrade Buildings!"
    draw_rounded_card(img, (s_x0 + 50, s_y1 - 140, s_x1 - 50, s_y1 - 40), radius=28,
                      fill_color=(198, 125, 45), border_color=(255, 215, 100), border_width=3, shadow_blur=10)
    font_bar = get_font(38, bold=True)
    draw.text(((s_x0 + s_x1) // 2, s_y1 - 90), "⭐ SOLVE EQUATIONS  ➔  BUILD VILLAGE! ⭐", font=font_bar, fill=(255, 255, 255), anchor="mm")

    img.save(os.path.join(OUTPUT_DIR, "screenshot_1.png"))
    print("Saved screenshot_1.png")

# ==============================================================================
# SCREENSHOT 2: CORE PUZZLE GAMEPLAY
# ==============================================================================
def generate_screenshot_2():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    draw_vertical_gradient(draw, W, H, (70, 42, 22), (32, 18, 10))

    draw_titles(draw, "RELAXING MATH CROSSWORDS", "Hundreds of Handcrafted Brain-Training Puzzles", pill_text="🧠 BRAIN TRAINING")

    phone_x, phone_y, phone_w, phone_h = 100, 390, 880, 1470
    s_x0, s_y0, s_x1, s_y1 = draw_phone_frame(img, phone_x, phone_y, phone_w, phone_h, bg_color=(36, 26, 18))

    # Top Level Bar in game
    draw = ImageDraw.Draw(img)
    draw_rounded_card(img, (s_x0 + 40, s_y0 + 80, s_x1 - 40, s_y0 + 170), radius=24, fill_color=(56, 40, 28), shadow_blur=8)
    draw.text((s_x0 + 80, s_y0 + 125), "LEVEL 42 • MEDIUM", font=get_font(36, bold=True), fill=(255, 225, 160), anchor="lm")
    draw.text((s_x1 - 80, s_y0 + 125), "🪙 1,240   💡 5", font=get_font(34, bold=True), fill=(255, 215, 0), anchor="rm")

    # Main Puzzle Grid
    board_rect = (s_x0 + 40, s_y0 + 210, s_x1 - 40, s_y0 + 960)
    draw_rounded_card(img, board_rect, radius=36, fill_color=(48, 34, 22), border_color=(140, 105, 65), border_width=3, shadow_blur=16)

    grid = [
        ("9", True, 0, 0), ("+", False, 1, 0), ("8", True, 2, 0), ("=", False, 3, 0), ("17", True, 4, 0),
        ("×", False, 0, 1),                        ("−", False, 4, 1),
        ("2", True, 0, 2), ("+", False, 1, 2), ("4", True, 2, 2), ("=", False, 3, 2), ("6", True, 4, 2),
        ("=", False, 0, 3),                        ("=", False, 4, 3),
        ("18", True, 0, 4), ("−", False, 1, 4), ("7", True, 2, 4), ("=", False, 3, 4), ("11", True, 4, 4),
    ]

    start_gx = s_x0 + 80
    start_gy = s_y0 + 250
    cell_size = 112
    gap = 20
    font_num = get_font(52, bold=True)
    font_op = get_font(54, bold=True)

    for val, is_num, col, row in grid:
        cx = start_gx + col * (cell_size + gap)
        cy = start_gy + row * (cell_size + gap)
        if is_num:
            # Check if active cell
            is_active = (col == 2 and row == 2)
            bg = (255, 240, 190) if is_active else (225, 185, 125)
            border = (255, 160, 0) if is_active else (255, 230, 180)
            draw_rounded_card(img, (cx, cy, cx + cell_size, cy + cell_size), radius=22,
                              fill_color=bg, border_color=border, border_width=3 if is_active else 2, shadow_blur=8)
            draw.text((cx + cell_size // 2, cy + cell_size // 2 - 4), val, font=font_num, fill=(60, 40, 20), anchor="mm")
        else:
            draw.text((cx + cell_size // 2, cy + cell_size // 2 - 4), val, font=font_op, fill=(245, 215, 140), anchor="mm")

    # Number Selection Tray at Bottom
    tray_rect = (s_x0 + 40, s_y0 + 1010, s_x1 - 40, s_y1 - 60)
    draw_rounded_card(img, tray_rect, radius=32, fill_color=(38, 28, 20), border_color=(90, 68, 48), border_width=2)
    draw.text(((s_x0 + s_x1) // 2, s_y0 + 1055), "NUMBER TRAY", font=get_font(28, bold=True), fill=(200, 180, 150), anchor="mm")

    tray_numbers = ["1", "3", "4", "5", "8", "9"]
    start_tx = s_x0 + 75
    t_cell = 100
    t_gap = 18
    for i, num in enumerate(tray_numbers):
        tcx = start_tx + i * (t_cell + t_gap)
        tcy = s_y0 + 1100
        draw_rounded_card(img, (tcx, tcy, tcx + t_cell, tcy + t_cell), radius=20,
                          fill_color=(235, 195, 135), border_color=(255, 240, 200), border_width=2, shadow_blur=6)
        draw.text((tcx + t_cell // 2, tcy + t_cell // 2 - 3), num, font=font_num, fill=(50, 30, 10), anchor="mm")

    # Hint and Smart Tools Row
    draw_rounded_card(img, (s_x0 + 80, s_y0 + 1250, s_x0 + 360, s_y0 + 1350), radius=24, fill_color=(70, 140, 75))
    draw.text((s_x0 + 220, s_y0 + 1300), "💡 HINT", font=get_font(36, bold=True), fill=(255, 255, 255), anchor="mm")

    draw_rounded_card(img, (s_x1 - 360, s_y0 + 1250, s_x1 - 80, s_y0 + 1350), radius=24, fill_color=(185, 115, 45))
    draw.text((s_x1 - 220, s_y0 + 1300), "⚡ MEGA HINT", font=get_font(34, bold=True), fill=(255, 255, 255), anchor="mm")

    img.save(os.path.join(OUTPUT_DIR, "screenshot_2.png"))
    print("Saved screenshot_2.png")

# ==============================================================================
# SCREENSHOT 3: COZY VILLAGE SIMULATION
# ==============================================================================
def generate_screenshot_3():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    draw_vertical_gradient(draw, W, H, (30, 68, 92), (14, 34, 48))

    draw_titles(draw, "BUILD & EXPAND OAKHEART", "Upgrade Cozy Buildings & Meet Cute Villagers", pill_text="🏡 VILLAGE BUILDER")

    phone_x, phone_y, phone_w, phone_h = 100, 390, 880, 1470
    s_x0, s_y0, s_x1, s_y1 = draw_phone_frame(img, phone_x, phone_y, phone_w, phone_h, bg_color=(20, 35, 42))

    # Island background
    island = safe_load_image("assets/images/village/meadow/island_bg.webp", resize=(820, 600))
    if island:
        img.paste(island, (s_x0 + 15, s_y0 + 160), island)

    # Buildings on island
    cottage = safe_load_image("assets/images/village/meadow/cottage_stage3.webp", resize=(250, 250))
    if cottage:
        img.paste(cottage, (s_x0 + 80, s_y0 + 360), cottage)

    bakery = safe_load_image("assets/images/village/meadow/bakery_stage3.webp", resize=(250, 250))
    if bakery:
        img.paste(bakery, (s_x0 + 470, s_y0 + 340), bakery)

    windmill = safe_load_image("assets/images/village/meadow/windmill_stage3.webp", resize=(240, 290))
    if windmill:
        img.paste(windmill, (s_x0 + 290, s_y0 + 200), windmill)

    # Floating Coin Bubbles above buildings
    draw = ImageDraw.Draw(img)
    draw_rounded_card(img, (s_x0 + 140, s_y0 + 310, s_x0 + 280, s_y0 + 375), radius=22,
                      fill_color=(255, 215, 0), border_color=(255, 255, 255), border_width=3, shadow_blur=10)
    draw.text((s_x0 + 210, s_y0 + 340), "+50 🪙", font=get_font(34, bold=True), fill=(60, 40, 10), anchor="mm")

    draw_rounded_card(img, (s_x0 + 530, s_y0 + 290, s_x0 + 670, s_y0 + 355), radius=22,
                      fill_color=(255, 215, 0), border_color=(255, 255, 255), border_width=3, shadow_blur=10)
    draw.text((s_x0 + 600, s_y0 + 320), "+1 💡", font=get_font(34, bold=True), fill=(60, 40, 10), anchor="mm")

    # Villagers Showcase Cards at bottom
    draw_rounded_card(img, (s_x0 + 30, s_y0 + 780, s_x1 - 30, s_y1 - 60), radius=36,
                      fill_color=(28, 44, 52), border_color=(60, 88, 102), border_width=3, shadow_blur=16)

    draw.text(((s_x0 + s_x1) // 2, s_y0 + 830), "🐾 ADORABLE ANIMAL COMPANIONS", font=get_font(34, bold=True), fill=(255, 225, 160), anchor="mm")

    # 3 Animal Cards
    card_w = 230
    card_h = 380
    card_y = s_y0 + 880

    animals = [
        ("Bramble", "assets/images/village/villagers/bunny_hd.webp", "Hops & explores!"),
        ("Professor Hoot", "assets/images/village/villagers/owl_hd.webp", "Math wisdom!"),
        ("Fern", "assets/images/village/villagers/fox_hd.webp", "Playful & quick!"),
    ]

    for idx, (name, icon_p, desc) in enumerate(animals):
        cx0 = s_x0 + 55 + idx * (card_w + 35)
        cx1 = cx0 + card_w
        draw_rounded_card(img, (cx0, card_y, cx1, card_y + card_h), radius=24,
                          fill_color=(42, 62, 72), border_color=(90, 120, 136), border_width=2)
        im = safe_load_image(icon_p, resize=(160, 160))
        if im:
            img.paste(im, (cx0 + 35, card_y + 35), im)
        draw.text((cx0 + card_w // 2, card_y + 225), name, font=get_font(28, bold=True), fill=(255, 255, 255), anchor="mm")
        draw.text((cx0 + card_w // 2, card_y + 270), desc, font=get_font(22, bold=False), fill=(210, 230, 240), anchor="mm")
        # Upgrade pill
        draw_rounded_card(img, (cx0 + 20, card_y + 310, cx1 - 20, card_y + 355), radius=16, fill_color=(212, 145, 55))
        draw.text((cx0 + card_w // 2, card_y + 332), "FRIEND LV. 3", font=get_font(20, bold=True), fill=(255, 255, 255), anchor="mm")

    # Postcard Share Pill
    draw_rounded_card(img, (s_x0 + 80, s_y1 - 130, s_x1 - 80, s_y1 - 50), radius=22, fill_color=(45, 120, 85))
    draw.text(((s_x0 + s_x1) // 2, s_y1 - 90), "📸 SHARE POSTCARDS WITH FRIENDS", font=get_font(30, bold=True), fill=(255, 255, 255), anchor="mm")

    img.save(os.path.join(OUTPUT_DIR, "screenshot_3.png"))
    print("Saved screenshot_3.png")

# ==============================================================================
# SCREENSHOT 4: DAILY CHALLENGES & LEADERBOARDS
# ==============================================================================
def generate_screenshot_4():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    draw_vertical_gradient(draw, W, H, (55, 28, 75), (24, 12, 36))

    draw_titles(draw, "DAILY CHALLENGES & RANKS", "Compete Globally & Unlock Custom Trophies", pill_text="🏆 GOOGLE PLAY GAMES")

    phone_x, phone_y, phone_w, phone_h = 100, 390, 880, 1470
    s_x0, s_y0, s_x1, s_y1 = draw_phone_frame(img, phone_x, phone_y, phone_w, phone_h, bg_color=(28, 18, 38))

    # Daily Streak Card
    draw = ImageDraw.Draw(img)
    streak_rect = (s_x0 + 40, s_y0 + 80, s_x1 - 40, s_y0 + 290)
    draw_rounded_card(img, streak_rect, radius=32, fill_color=(54, 30, 72), border_color=(160, 95, 210), border_width=3, shadow_blur=14)
    draw.text((s_x0 + 90, s_y0 + 145), "🔥 7-DAY STREAK!", font=get_font(54, bold=True), fill=(255, 185, 45), anchor="lm")
    draw.text((s_x0 + 90, s_y0 + 215), "Daily puzzle solved • Streak reward claimed (+5 💡)", font=get_font(28, bold=False), fill=(230, 215, 245), anchor="lm")

    # Calendar Puzzles Strip
    cal_y = s_y0 + 330
    days = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
    day_w = 98
    for i, d in enumerate(days):
        dx = s_x0 + 55 + i * (day_w + 14)
        is_today = (i == 4)
        bg = (212, 145, 45) if is_today else (44, 25, 58)
        border = (255, 215, 0) if is_today else (80, 50, 105)
        draw_rounded_card(img, (dx, cal_y, dx + day_w, cal_y + 110), radius=18, fill_color=bg, border_color=border, border_width=2)
        draw.text((dx + day_w // 2, cal_y + 35), d, font=get_font(22, bold=True), fill=(240, 220, 255), anchor="mm")
        draw.text((dx + day_w // 2, cal_y + 75), "✔" if i <= 4 else str(i + 1), font=get_font(30, bold=True), fill=(255, 255, 255), anchor="mm")

    # Google Play Games Achievements Showcase
    ach_rect = (s_x0 + 40, s_y0 + 490, s_x1 - 40, s_y0 + 860)
    draw_rounded_card(img, ach_rect, radius=32, fill_color=(42, 24, 58), border_color=(120, 70, 160), border_width=3, shadow_blur=14)
    draw.text(((s_x0 + s_x1) // 2, s_y0 + 540), "🎖️ GOOGLE PLAY ACHIEVEMENTS", font=get_font(34, bold=True), fill=(255, 225, 160), anchor="mm")

    trophies = [
        ("assets/images/achievements/crossmath_legend.png", "Legend", "1,000 Puzzles"),
        ("assets/images/achievements/math_apprentice.png", "Apprentice", "50 Solved"),
        ("assets/images/achievements/on_fire.png", "On Fire", "7-Day Streak"),
    ]
    t_w = 210
    for idx, (path, title, sub) in enumerate(trophies):
        tx = s_x0 + 65 + idx * (t_w + 45)
        ty = s_y0 + 580
        im = safe_load_image(path, resize=(150, 150))
        if im:
            img.paste(im, (tx + 30, ty), im)
        draw.text((tx + t_w // 2, ty + 190), title, font=get_font(28, bold=True), fill=(255, 255, 255), anchor="mm")
        draw.text((tx + t_w // 2, ty + 230), sub, font=get_font(22, bold=False), fill=(210, 190, 230), anchor="mm")

    # Live Leaderboard Card
    lead_rect = (s_x0 + 40, s_y0 + 910, s_x1 - 40, s_y1 - 60)
    draw_rounded_card(img, lead_rect, radius=32, fill_color=(48, 28, 66), border_color=(140, 85, 190), border_width=3, shadow_blur=14)
    draw.text(((s_x0 + s_x1) // 2, s_y0 + 960), "🌍 GLOBAL LEADERBOARDS", font=get_font(34, bold=True), fill=(255, 225, 160), anchor="mm")

    ranks = [
        ("#1", "MathMaster_99", "2,450 Brain Power", (255, 215, 0)),
        ("#2", "OakheartPuzzler", "2,180 Brain Power", (220, 220, 230)),
        ("#3", "You (NumberHaven)", "1,940 Brain Power", (218, 165, 95)),
    ]
    for idx, (rank, name, score, r_color) in enumerate(ranks):
        ry = s_y0 + 1020 + idx * 115
        is_you = ("You" in name)
        bg = (75, 42, 102) if is_you else (38, 22, 54)
        border = (255, 215, 0) if is_you else (70, 45, 95)
        draw_rounded_card(img, (s_x0 + 70, ry, s_x1 - 70, ry + 95), radius=20, fill_color=bg, border_color=border, border_width=2 if is_you else 1)
        draw.text((s_x0 + 120, ry + 47), rank, font=get_font(36, bold=True), fill=r_color, anchor="mm")
        draw.text((s_x0 + 180, ry + 32), name, font=get_font(30, bold=True), fill=(255, 255, 255), anchor="lm")
        draw.text((s_x0 + 180, ry + 68), score, font=get_font(22, bold=False), fill=(200, 185, 220), anchor="lm")

    img.save(os.path.join(OUTPUT_DIR, "screenshot_4.png"))
    print("Saved screenshot_4.png")

# ==============================================================================
# SCREENSHOT 5: PLAY OFFLINE & ACCESSIBILITY
# ==============================================================================
def generate_screenshot_5():
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)
    draw_vertical_gradient(draw, W, H, (22, 32, 42), (10, 14, 20))

    draw_titles(draw, "PLAY ANYTIME — 100% OFFLINE", "No WiFi Needed • Cozy Dark Mode & High Contrast", pill_text="✈️ PLAY ANYWHERE")

    phone_x, phone_y, phone_w, phone_h = 100, 390, 880, 1470
    s_x0, s_y0, s_x1, s_y1 = draw_phone_frame(img, phone_x, phone_y, phone_w, phone_h, bg_color=(18, 24, 30))

    # Top Offline Status Pill in game
    draw = ImageDraw.Draw(img)
    draw_rounded_card(img, (s_x0 + 40, s_y0 + 80, s_x1 - 40, s_y0 + 200), radius=28,
                      fill_color=(28, 40, 54), border_color=(60, 95, 130), border_width=3, shadow_blur=10)
    draw.text(((s_x0 + s_x1) // 2, s_y0 + 120), "✈️ 100% OFFLINE PLAY SUPPORTED", font=get_font(36, bold=True), fill=(255, 255, 255), anchor="mm")
    draw.text(((s_x0 + s_x1) // 2, s_y0 + 165), "No internet connection or WiFi required", font=get_font(24, bold=False), fill=(180, 210, 235), anchor="mm")

    # Dark Mode Tavern Board
    board_rect = (s_x0 + 40, s_y0 + 240, s_x1 - 40, s_y0 + 940)
    draw_rounded_card(img, board_rect, radius=36, fill_color=(24, 30, 38), border_color=(75, 95, 120), border_width=3, shadow_blur=16)

    draw.text(((s_x0 + s_x1) // 2, s_y0 + 290), "🌙 COZY DARK TAVERN THEME", font=get_font(32, bold=True), fill=(255, 215, 140), anchor="mm")

    dark_grid = [
        ("15", True, 0, 0), ("−", False, 1, 0), ("6", True, 2, 0), ("=", False, 3, 0), ("9", True, 4, 0),
        ("÷", False, 0, 1),                        ("×", False, 4, 1),
        ("3", True, 0, 2), ("+", False, 1, 2), ("5", True, 2, 2), ("=", False, 3, 2), ("8", True, 4, 2),
        ("=", False, 0, 3),                        ("=", False, 4, 3),
        ("5", True, 0, 4), ("+", False, 1, 4), ("2", True, 2, 4), ("=", False, 3, 4), ("72", True, 4, 4),
    ]

    start_gx = s_x0 + 80
    start_gy = s_y0 + 340
    cell_size = 112
    gap = 20
    font_num = get_font(52, bold=True)
    font_op = get_font(54, bold=True)

    for val, is_num, col, row in dark_grid:
        cx = start_gx + col * (cell_size + gap)
        cy = start_gy + row * (cell_size + gap)
        if is_num:
            draw_rounded_card(img, (cx, cy, cx + cell_size, cy + cell_size), radius=22,
                              fill_color=(40, 50, 62), border_color=(90, 115, 145), border_width=2, shadow_blur=8)
            draw.text((cx + cell_size // 2, cy + cell_size // 2 - 4), val, font=font_num, fill=(240, 245, 255), anchor="mm")
        else:
            draw.text((cx + cell_size // 2, cy + cell_size // 2 - 4), val, font=font_op, fill=(255, 205, 110), anchor="mm")

    # Accessibility Showcase at Bottom
    acc_rect = (s_x0 + 40, s_y0 + 980, s_x1 - 40, s_y1 - 60)
    draw_rounded_card(img, acc_rect, radius=32, fill_color=(26, 36, 46), border_color=(65, 88, 112), border_width=3, shadow_blur=14)

    draw.text(((s_x0 + s_x1) // 2, s_y0 + 1030), "👁️ DESIGNED FOR EVERYONE", font=get_font(34, bold=True), fill=(255, 225, 160), anchor="mm")

    features = [
        ("🌙 Dark Mode", "Reduces eye strain for relaxing bedtime play"),
        ("🎨 High Contrast", "Clear color-blind friendly equation & tile cues"),
        ("📳 Tactile Haptics", "Satisfying subtle vibrations on number placement"),
    ]

    for idx, (ftitle, fdesc) in enumerate(features):
        fy = s_y0 + 1080 + idx * 115
        draw_rounded_card(img, (s_x0 + 70, fy, s_x1 - 70, fy + 95), radius=20, fill_color=(36, 48, 62), border_color=(75, 100, 128), border_width=2)
        draw.text((s_x0 + 100, fy + 32), ftitle, font=get_font(28, bold=True), fill=(255, 255, 255), anchor="lm")
        draw.text((s_x0 + 100, fy + 68), fdesc, font=get_font(22, bold=False), fill=(185, 205, 225), anchor="lm")

    img.save(os.path.join(OUTPUT_DIR, "screenshot_5.png"))
    print("Saved screenshot_5.png")

# Generate all 5
generate_screenshot_1()
generate_screenshot_2()
generate_screenshot_3()
generate_screenshot_4()
generate_screenshot_5()

print("ALL 5 HIGH-CONVERTING SCREENSHOTS GENERATED SUCCESSFULLY!")
