from PIL import Image, ImageDraw

SIZE = 1024
BG = (0x2F, 0x6B, 0x4F)   # deep calm green — matches AccentColor light value
FG = (0xF6, 0xEF, 0xE1)   # warm cream — matches CardBackground light value

img = Image.new("RGB", (SIZE, SIZE), BG)
draw = ImageDraw.Draw(img)

cx, cy = SIZE // 2, SIZE // 2
half_w = 300
half_h = 220
spine_gap = 14

left_page = [
    (cx - spine_gap - half_w, cy - half_h + 40),
    (cx - spine_gap, cy - half_h),
    (cx - spine_gap, cy + half_h),
    (cx - spine_gap - half_w, cy + half_h - 40),
]
right_page = [
    (cx + spine_gap + half_w, cy - half_h + 40),
    (cx + spine_gap, cy - half_h),
    (cx + spine_gap, cy + half_h),
    (cx + spine_gap + half_w, cy + half_h - 40),
]

draw.polygon(left_page, fill=FG)
draw.polygon(right_page, fill=FG)
draw.line([(cx, cy - half_h), (cx, cy + half_h)], fill=BG, width=10)

img.save("HadithEnglish/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")
print("OK: wrote AppIcon-1024.png")
