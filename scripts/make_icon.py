# -*- coding: utf-8 -*-
"""
ALGOPA 앱 아이콘 생성기.
- 1024x1024 PNG
- 배경: #4263EB Indigo full bleed
- 중앙: 흰색 "A" (Pretendard Bold)
- 두 파일 출력:
    assets/icon/app_icon.png            -- iOS/일반 launcher용 (배경 포함)
    assets/icon/app_icon_foreground.png -- Android adaptive icon용 (transparent bg)
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFont

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
ICON_DIR = os.path.join(ROOT, "assets", "icon")
FONT_PATH = os.path.join(ROOT, "assets", "fonts", "Pretendard-Bold.otf")
os.makedirs(ICON_DIR, exist_ok=True)

SIZE = 1024
BG = (66, 99, 235)        # #4263EB
FG = (255, 255, 255)      # white
TEXT = "A"

# 글자 크기: 아이콘 높이의 ~55% (안전 영역 내)
font_size = int(SIZE * 0.55)
font = ImageFont.truetype(FONT_PATH, font_size)


def measure(font, text):
    """anchored bounding box of text."""
    dummy = Image.new("RGBA", (SIZE, SIZE))
    d = ImageDraw.Draw(dummy)
    bbox = d.textbbox((0, 0), text, font=font)
    return bbox  # (l, t, r, b)


bbox = measure(font, TEXT)
text_w = bbox[2] - bbox[0]
text_h = bbox[3] - bbox[1]

# 시각적 중앙: bbox offset 보정 + Pretendard 시각 중심이 약간 위쪽으로 치우치므로
# baseline을 살짝 아래로 (~25px) 이동시켜 광학 중앙 맞춤.
x = (SIZE - text_w) // 2 - bbox[0]
y = (SIZE - text_h) // 2 - bbox[1] + 25


def draw_icon(bg_color):
    if bg_color is None:
        img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    else:
        img = Image.new("RGBA", (SIZE, SIZE), (*bg_color, 255))
    d = ImageDraw.Draw(img)
    d.text((x, y), TEXT, font=font, fill=FG)
    return img


# 1) 일반 아이콘 (배경 포함)
img_main = draw_icon(BG)
img_main.convert("RGB").save(
    os.path.join(ICON_DIR, "app_icon.png"), "PNG", optimize=True
)

# 2) Android adaptive foreground (배경 transparent)
img_fg = draw_icon(None)
img_fg.save(
    os.path.join(ICON_DIR, "app_icon_foreground.png"), "PNG", optimize=True
)

print(f"=== Done ===")
for name in ("app_icon.png", "app_icon_foreground.png"):
    path = os.path.join(ICON_DIR, name)
    kb = os.path.getsize(path) / 1024
    print(f"  {name:30s} {kb:6.1f} KB")
