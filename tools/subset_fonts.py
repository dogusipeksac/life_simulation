#!/usr/bin/env python3
"""Noto Serif'i Türkçe/Latin karakterlere ve içerikte geçen her karaktere indirger (P6 boyut).

Kullanım (proje kökünden): python3 tools/subset_fonts.py <kaynak_ttf_klasörü>
Kaynak: Google Fonts'taki tam NotoSerif-{Regular,Medium,SemiBold}.ttf. Çıktı assets/fonts/ altına yazılır.
Oyuncu adında kapsam dışı bir karakter olursa Flutter sistem yazı tipine düşer.
"""
import pathlib, sys
from fontTools import subset

ROOT = pathlib.Path(__file__).resolve().parent.parent
src = pathlib.Path(sys.argv[1])
chars = set()
for path in list((ROOT / "assets/content").rglob("*.json")) + list((ROOT / "lib").rglob("*.dart")):
    chars |= set(path.read_text(encoding="utf-8"))
ranges = [(0x20, 0x7E), (0xA0, 0x17F), (0x2010, 0x205E), (0x20A0, 0x20C0), (0x2190, 0x21FF), (0x25A0, 0x25FF)]
for a, b in ranges:
    chars |= {chr(c) for c in range(a, b + 1)}
unicodes = sorted(ord(c) for c in chars if ord(c) >= 0x20)
for name in ("Regular", "Medium", "SemiBold"):
    options = subset.Options()
    options.layout_features = ["kern", "liga", "clig", "calt", "ccmp", "locl", "mark", "mkmk", "onum", "lnum", "pnum", "tnum"]
    options.name_IDs = ["*"]
    options.notdef_outline = True
    font = subset.load_font(str(src / f"NotoSerif-{name}.ttf"), options)
    s = subset.Subsetter(options)
    s.populate(unicodes=unicodes)
    s.subset(font)
    out = ROOT / "assets/fonts" / f"NotoSerif-{name}.ttf"
    subset.save_font(font, str(out), options)
    print(out.name, out.stat().st_size // 1024, "KB")
