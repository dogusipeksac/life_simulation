#!/usr/bin/env python3
"""Uygulama simgesi, mağaza özellik grafiği ve mağaza ekran görüntülerini üretir.

Kullanım (proje kökünden):
    python3 tools/store_art.py icon          # store/icon/* (simge kaynakları + Play 512 px)
    python3 tools/store_art.py feature       # store/play/feature_graphic_1024x500.png
    python3 tools/store_art.py screenshots   # store/play/screenshots/*, store/appstore/*
Ekran görüntüsü kaynakları store/raw/*.png (emülatörden 1080x2424). Gerekir: Pillow.
"""
import math
import pathlib
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
STORE = ROOT / "store"
FONT_DIR = ROOT / "assets" / "fonts"

# "Gece kitabı" paleti (lib/design/palette.dart)
BG_TOP = (43, 33, 66)
BG_BOTTOM = (14, 12, 22)
INK = (239, 234, 224)
MUTED = (156, 147, 168)
ACCENT = (224, 180, 114)
PAGE = (242, 233, 214)
PAGE_SHADE = (214, 199, 172)


def font(size, weight="SemiBold"):
    return ImageFont.truetype(str(FONT_DIR / f"NotoSerif-{weight}.ttf"), size)


def vertical_gradient(w, h, top, bottom):
    img = Image.new("RGB", (w, h), top)
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        c = tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        for x in range(w):
            px[x, y] = c
    return img


def glow(size, center, radius, color, alpha):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    cx, cy = center
    d.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=color + (alpha,))
    return layer.filter(ImageFilter.GaussianBlur(radius * 0.45))


def bezier(p0, p1, p2, p3, n=48):
    pts = []
    for i in range(n + 1):
        t = i / n
        a = (1 - t) ** 3
        b = 3 * (1 - t) ** 2 * t
        c = 3 * (1 - t) * t ** 2
        d = t ** 3
        pts.append((a * p0[0] + b * p1[0] + c * p2[0] + d * p3[0], a * p0[1] + b * p1[1] + c * p2[1] + d * p3[1]))
    return pts


def draw_motif(img, scale=1.0, mono=None):
    """Açık kitap + hilal + yıldız; [img] kare, motif merkezde [scale] oranında."""
    s = img.size[0]
    d = ImageDraw.Draw(img)
    u = s * scale / 100.0  # motif birimi: 100 birim = motif genişliği
    ox = (s - 100 * u) / 2
    oy = (s - 100 * u) / 2

    def P(x, y):
        return (ox + x * u, oy + y * u)

    page = mono or PAGE
    shade = mono or PAGE_SHADE
    accent = mono or ACCENT

    # Kitap: iki sayfa, ortada sırt; alt kenar hafif kavisli.
    spine_top, spine_bottom = P(50, 58), P(50, 90)
    left = bezier(P(50, 58), P(38, 50), P(20, 50), P(6, 56)) + bezier(P(6, 56), P(6, 66), P(6, 76), P(6, 86)) \
        + bezier(P(6, 86), P(20, 80), P(38, 82), P(50, 90))
    right = bezier(P(50, 58), P(62, 50), P(80, 50), P(94, 56)) + bezier(P(94, 56), P(94, 66), P(94, 76), P(94, 86)) \
        + bezier(P(94, 86), P(80, 80), P(62, 82), P(50, 90))
    d.polygon(left, fill=page)
    d.polygon(right, fill=shade if mono is None else page)
    if mono is None:
        # Sayfa çizgileri: yazının izi.
        for i, y in enumerate((63, 69, 75)):
            d.line(bezier(P(14, y), P(24, y - 4), P(36, y - 4), P(44, y + 1), 24), fill=(196, 180, 150), width=max(2, round(u * 1.1)))
            d.line(bezier(P(56, y + 1), P(64, y - 4), P(76, y - 4), P(86, y), 24), fill=(186, 168, 138), width=max(2, round(u * 1.1)))
        d.line((spine_top, spine_bottom), fill=(150, 128, 98), width=max(2, round(u * 1.4)))
    else:
        d.line((spine_top, spine_bottom), fill=(0, 0, 0, 0), width=max(2, round(u * 2.2)))

    # Hilal: dolu daire, üstüne zemin renginde (ya da şeffaf) kaydırılmış daire.
    cx, cy, r = 50, 27, 17
    d.ellipse((*P(cx - r, cy - r), *P(cx + r, cy + r)), fill=accent)
    cut = (0, 0, 0, 0) if img.mode == "RGBA" else BG_TOP
    if img.mode == "RGBA":
        mask = Image.new("L", img.size, 0)
        ImageDraw.Draw(mask).ellipse((*P(cx - r + 9, cy - r - 5), *P(cx + r + 9, cy + r - 5)), fill=255)
        img.paste(Image.new("RGBA", img.size, (0, 0, 0, 0)), (0, 0), mask)
    else:
        d.ellipse((*P(cx - r + 9, cy - r - 5), *P(cx + r + 9, cy + r - 5)), fill=cut)

    # Yıldız ✦: dört köşeli.
    sx, sy, sr = 76, 18, 7
    star = []
    for k in range(8):
        a = math.pi / 4 * k - math.pi / 2
        rr = sr if k % 2 == 0 else sr * 0.32
        star.append(P(sx + rr * math.cos(a), sy + rr * math.sin(a)))
    ImageDraw.Draw(img).polygon(star, fill=accent)


def make_icon():
    out = STORE / "icon"
    out.mkdir(parents=True, exist_ok=True)
    S = 4096
    # 1) Tam simge (iOS, Play 512, eski Android): zemin + parıltı + motif.
    bg = vertical_gradient(S, S, BG_TOP, BG_BOTTOM).convert("RGBA")
    bg.alpha_composite(glow((S, S), (S * 0.5, S * 0.30), S * 0.30, ACCENT, 60))
    # Motifi ayrı katmanda çiz ki hilal kesiği zemine değil şeffaflığa uygulansın.
    motif = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw_motif(motif, scale=0.70)
    full = bg.copy()
    full.alpha_composite(motif)
    full = full.convert("RGB")
    full.resize((1024, 1024), Image.LANCZOS).save(out / "icon_1024.png", optimize=True)
    (STORE / "play").mkdir(parents=True, exist_ok=True)
    full.resize((512, 512), Image.LANCZOS).save(STORE / "play" / "icon_512.png", optimize=True)

    # 2) Uyarlanabilir simge (Android 8+): ön plan güvenli alanda (%66), arka plan ayrı.
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw_motif(fg, scale=0.50)
    fg.resize((1024, 1024), Image.LANCZOS).save(out / "adaptive_foreground.png", optimize=True)
    back = vertical_gradient(1024, 1024, BG_TOP, BG_BOTTOM).convert("RGBA")
    back.alpha_composite(glow((1024, 1024), (512, 330), 300, ACCENT, 55))
    back.convert("RGB").save(out / "adaptive_background.png", optimize=True)

    # 3) Tek renk (Android 13 temalı simgeler).
    mono = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw_motif(mono, scale=0.50, mono=(255, 255, 255, 255))
    mono.resize((1024, 1024), Image.LANCZOS).save(out / "adaptive_monochrome.png", optimize=True)
    print("icon: store/icon/*, store/play/icon_512.png")


# ---------------------------------------------------------------- Mağaza görselleri

def text_center(d, xy_box, text, fnt, fill, line_gap=1.18):
    """[xy_box] = (x0, y0, x1): metni kutu genişliğine sararak ortalar; bitiş y döner."""
    x0, y, x1 = xy_box
    words, lines, cur = text.split(), [], ""
    for w in words:
        test = (cur + " " + w).strip()
        if d.textlength(test, font=fnt) <= x1 - x0:
            cur = test
        else:
            lines.append(cur)
            cur = w
    lines.append(cur)
    for line in lines:
        wpx = d.textlength(line, font=fnt)
        d.text((x0 + (x1 - x0 - wpx) / 2, y), line, font=fnt, fill=fill)
        y += fnt.size * line_gap
    return y


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, *img.size), radius, fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def compose_screenshot(src, title, subtitle, size):
    W, H = size
    canvas = vertical_gradient(W, H, BG_TOP, BG_BOTTOM).convert("RGBA")
    canvas.alpha_composite(glow((W, H), (W * 0.82, H * 0.06), W * 0.55, ACCENT, 45))
    d = ImageDraw.Draw(canvas)
    k = W / 1080
    y = text_center(d, (70 * k, 92 * k, W - 70 * k), title, font(round(74 * k)), ACCENT)
    y = text_center(d, (90 * k, y + 14 * k, W - 90 * k), subtitle, font(round(38 * k), "Regular"), INK)
    # Ekran görüntüsü: durum çubuğunu kırp, yuvarlak köşeli bir "telefon" içinde.
    shot = Image.open(src).convert("RGB")
    shot = shot.crop((0, 96, shot.width, shot.height - 40))
    top = y + 46 * k
    avail_h = H - top - 60 * k
    sw = min(W * 0.80, avail_h * shot.width / shot.height)
    sh = sw * shot.height / shot.width
    shot = shot.resize((round(sw), round(sh)), Image.LANCZOS)
    frame_pad = round(14 * k)
    frame = Image.new("RGBA", (shot.width + 2 * frame_pad, shot.height + 2 * frame_pad), (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle((0, 0, *frame.size), round(58 * k), fill=(30, 26, 44, 255), outline=(70, 60, 96, 255), width=round(3 * k))
    frame.alpha_composite(rounded(shot.convert("RGBA"), round(46 * k)), (frame_pad, frame_pad))
    fx = round((W - frame.width) / 2)
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((fx + 10, top + 24, fx + frame.width + 10, top + frame.height + 24), round(58 * k), fill=(0, 0, 0, 120))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(28 * k)))
    canvas.alpha_composite(frame, (fx, round(top)))
    return canvas.convert("RGB")


SCREENS = [
    ("01_title.png", "Bir hayatın kitabı", "Doğumdan yüz yaşına, kararlarınla yazılan bir hayat."),
    ("02_fate.png", "Mesajlar, mektuplar, kayıtlar", "Hikâyeler sohbet balonlarıyla, notlarla ve telsiz dökümleriyle anlatılır."),
    ("03_moment.png", "Sadece okuma, yaşa", "Nefes al, zamanla, eşleştir, bütçe yap: 66 etkileşimli an."),
    ("04_story.png", "Her kararın bir izi var", "Seçimlerin ailene, işine ve geleceğine dokunur."),
    ("05_career.png", "Kariyerini kur", "103 meslek, terfiler, maaşlar ve hayat hedefleri."),
    ("06_relations.png", "Bağlarını güçlendir", "Ailen, dostların ve birlikte geçirdiğin zaman."),
    ("07_library.png", "Başka bir hayat dene", "Şifreler, kanıtlar ve frekanslarla dallanan uzun hikâyeler."),
    ("08_lock.png", "Sırrı çöz", "Dolabın şifresi hikâyenin içinde saklı."),
]


def make_screenshots():
    raw = STORE / "raw"
    play = STORE / "play" / "screenshots"
    ios = STORE / "appstore" / "6.9in"
    play.mkdir(parents=True, exist_ok=True)
    ios.mkdir(parents=True, exist_ok=True)
    for name, title, sub in SCREENS:
        src = raw / name
        if not src.exists():
            print("eksik kaynak:", src)
            continue
        compose_screenshot(src, title, sub, (1080, 1920)).save(play / name, optimize=True)
        compose_screenshot(src, title, sub, (1320, 2868)).save(ios / name, optimize=True)
    print("screenshots: store/play/screenshots (1080x1920), store/appstore/6.9in (1320x2868)")


def make_feature():
    W, H = 1024, 500
    canvas = vertical_gradient(W, H, BG_TOP, BG_BOTTOM).convert("RGBA")
    canvas.alpha_composite(glow((W, H), (W * 0.78, H * 0.30), 260, ACCENT, 55))
    d = ImageDraw.Draw(canvas)
    # Tepeler (atmosfer şeridinin dili).
    for base, amp, freq, col in ((0.70, 0.10, 1.0, (60, 48, 86, 255)), (0.80, 0.08, 1.7, (34, 29, 51, 255)), (0.90, 0.06, 2.6, (21, 18, 31, 255))):
        pts = [(x, H * base - math.sin(x / W * math.pi * freq + freq) * H * amp) for x in range(0, W + 8, 8)]
        d.polygon(pts + [(W, H), (0, H)], fill=col)
    # Sağda simge motifi.
    motif = Image.new("RGBA", (420, 420), (0, 0, 0, 0))
    draw_motif(motif, scale=0.86)
    canvas.alpha_composite(motif, (W - 450, 18))
    d.text((60, 120), "Hayat Simülasyonu", font=font(62), fill=ACCENT)
    d.text((62, 205), "Bir hayatın kitabı.", font=font(32, "Regular"), fill=INK)
    d.text((62, 255), "Kararların, kaderin ve sırlarla dolu hikâyeler.", font=font(24, "Regular"), fill=MUTED)
    out = STORE / "play"
    out.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out / "feature_graphic_1024x500.png", optimize=True)
    print("feature: store/play/feature_graphic_1024x500.png")


if __name__ == "__main__":
    what = sys.argv[1:] or ["icon", "feature", "screenshots"]
    if "icon" in what:
        make_icon()
    if "feature" in what:
        make_feature()
    if "screenshots" in what:
        make_screenshots()
