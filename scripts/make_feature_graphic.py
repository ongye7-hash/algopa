# -*- coding: utf-8 -*-
"""
ALGOPA Play Store 피처 그래픽 생성기.
- 1024 x 500 PNG
- 배경: #4263EB Indigo 단색
- 좌측 정렬: "알고파" (Pretendard Bold, 흰색, 대형)
- 보조: "오늘 어디가세요?" (Pretendard Medium, 흰색 80% 투명도)
- 우측 액센트: 단순 흰색 둥근 사각형 (앱 아이콘 모티브)
- 출력: assets/store/feature_graphic.png
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFont

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUT_DIR = os.path.join(ROOT, "assets", "store")
FONT_BOLD = os.path.join(ROOT, "assets", "fonts", "Pretendard-Bold.otf")
FONT_MEDIUM = os.path.join(ROOT, "assets", "fonts", "Pretendard-Medium.otf")
os.makedirs(OUT_DIR, exist_ok=True)

W, H = 1024, 500
BG = (66, 99, 235)        # #4263EB
WHITE = (255, 255, 255)
WHITE_80 = (255, 255, 255, 204)  # 80% alpha

img = Image.new("RGB", (W, H), BG)
draw = ImageDraw.Draw(img, "RGBA")

# === 좌측: "알고파" 메인 ===
font_main = ImageFont.truetype(FONT_BOLD, 130)
text_main = "알고파"
bbox_m = draw.textbbox((0, 0), text_main, font=font_main)
mw = bbox_m[2] - bbox_m[0]
mh = bbox_m[3] - bbox_m[1]

LEFT = 80
TOP_MAIN = 130
draw.text((LEFT - bbox_m[0], TOP_MAIN - bbox_m[1]), text_main, font=font_main, fill=WHITE)

# === 좌측: 보조 카피 ===
font_sub = ImageFont.truetype(FONT_MEDIUM, 38)
text_sub = "오늘 어디가세요?"
bbox_s = draw.textbbox((0, 0), text_sub, font=font_sub)
draw.text(
    (LEFT - bbox_s[0], TOP_MAIN + mh + 30 - bbox_s[1]),
    text_sub,
    font=font_sub,
    fill=WHITE_80,
)

# === 우측: 앱 아이콘 모티브 (둥근 사각형 + 흰색 A) ===
# 큰 흰색 둥근 사각형 (반투명) — 우측에 시각 액센트
ICON_SIZE = 280
ICON_RIGHT = W - 80
ICON_TOP = (H - ICON_SIZE) // 2
ICON_LEFT = ICON_RIGHT - ICON_SIZE

draw.rounded_rectangle(
    [ICON_LEFT, ICON_TOP, ICON_RIGHT, ICON_TOP + ICON_SIZE],
    radius=56,
    fill=(255, 255, 255, 38),  # 흰색 15% — subtle 액센트
)

# 그 안에 흰색 "A" (앱 아이콘 일관성)
font_a = ImageFont.truetype(FONT_BOLD, 200)
bbox_a = draw.textbbox((0, 0), "A", font=font_a)
aw = bbox_a[2] - bbox_a[0]
ah = bbox_a[3] - bbox_a[1]
ax = ICON_LEFT + (ICON_SIZE - aw) // 2 - bbox_a[0]
ay = ICON_TOP + (ICON_SIZE - ah) // 2 - bbox_a[1] + 8
draw.text((ax, ay), "A", font=font_a, fill=WHITE)

out_path = os.path.join(OUT_DIR, "feature_graphic.png")
img.save(out_path, "PNG", optimize=True)
kb = os.path.getsize(out_path) / 1024
print(f"=== Done ===\n  {out_path}\n  {kb:.1f} KB")
