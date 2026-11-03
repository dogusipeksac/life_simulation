#!/usr/bin/env python3
"""Yerel mağaza yayını orkestratörü (Flutter iOS TestFlight + Android Play)."""

import argparse
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
CONFIG_PATH = Path.home() / ".config/life-simulation/release.env"
FLUTTER_BIN = Path("/Users/dogusipeksac/Documents/flutter/bin/flutter")


def log(msg):
    print(f"==> {msg}", flush=True)


def fail(msg):
    print(f"\nHATA: {msg}", file=sys.stderr, flush=True)
    sys.exit(1)


def run_cmd(args, *, env=None, cwd=ROOT):
    cmd_str = " ".join(str(a) for a in args)
    print(f"+ {cmd_str}", flush=True)
    res = subprocess.run([str(a) for a in args], cwd=cwd, env=env)
    if res.returncode != 0:
        fail(f"Komut başarısız oldu (çıkış kodu: {res.returncode}): {cmd_str}")


def load_config():
    if not CONFIG_PATH.is_file():
        fail(f"Ayar dosyası bulunamadı: {CONFIG_PATH}\n"
             f"Lütfen config/release.env.example dosyasını {CONFIG_PATH} konumuna kopyalayıp doldurun.")
    
    # İzin kontrolü (chmod 600)
    mode = CONFIG_PATH.stat().st_mode & 0o777
    if mode not in (0o600, 0o400):
        log(f"Uyarı: {CONFIG_PATH} izinleri çok geniş ({oct(mode)}). 'chmod 600 {CONFIG_PATH}' önerilir.")

    conf = {}
    for line in CONFIG_PATH.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            fail(f"Geçersiz satır: {line} ({CONFIG_PATH})")
        k, v = line.split("=", 1)
        conf[k.strip()] = v.strip().strip('"').strip("'")
    return conf


def verify_notes(version, platform):
    note_file = ROOT / "release_notes" / version / f"{platform}.txt"
    if not note_file.is_file():
        fail(f"Sürüm notu dosyası eksik: {note_file}")
    text = note_file.read_text(encoding="utf-8").strip()
    if not text:
        fail(f"Sürüm notu boş: {note_file}")
    limit = 4000 if platform == "ios" else 500
    if len(text) > limit:
        fail(f"{platform} sürüm notu sınırı aşıyor ({len(text)} > {limit} karakter): {note_file}")
    return text, note_file


def run_quality_checks():
    log("Kalite kontrolleri çalıştırılıyor (flutter analyze & flutter test)...")
    flutter = str(FLUTTER_BIN) if FLUTTER_BIN.is_file() else "flutter"
    run_cmd([flutter, "analyze", "--no-fatal-infos"])
    run_cmd([flutter, "test"])


def build_ios_ipa(version, build_number, export_options_plist):
    log(f"iOS IPA derleniyor (Sürüm: {version}, Build: {build_number})...")
    flutter = str(FLUTTER_BIN) if FLUTTER_BIN.is_file() else "flutter"
    
    out_dir = ROOT / "release/output/releases" / version / "ios" / str(build_number)
    out_dir.mkdir(parents=True, exist_ok=True)
    
    cmd = [
        flutter, "build", "ipa", "--release",
        f"--build-name={version}",
        f"--build-number={build_number}",
        f"--export-options-plist={export_options_plist}",
        "--obfuscate",
        f"--split-debug-info={out_dir}/symbols",
    ]
    run_cmd(cmd)
    
    ipa_candidates = list((ROOT / "build/ios/ipa").glob("*.ipa"))
    if not ipa_candidates:
        fail("Derleme tamamlandı ancak build/ios/ipa klasöründe .ipa dosyası bulunamadı.")
    
    target_ipa = out_dir / ipa_candidates[0].name
    shutil.copy2(ipa_candidates[0], target_ipa)
    log(f"IPA hazırlandı ve kopyalandı: {target_ipa}")
    return target_ipa


def upload_to_testflight(ipa_path, notes_path, config):
    log("Fastlane ile TestFlight'a yükleniyor...")
    fastlane_dir = ROOT / "release"
    env = os.environ.copy()
    env.update(config)
    env["LANG"] = "en_US.UTF-8"
    env["LC_ALL"] = "en_US.UTF-8"
    
    cmd = [
        "bundle", "exec", "fastlane", "tf_upload",
        f"ipa:{ipa_path}",
        f"notes:{notes_path}"
    ]
    run_cmd(cmd, env=env, cwd=fastlane_dir)
    log("TestFlight yüklemesi başarıyla tamamlandı!")


def update_history(version, build_number, platform, target):
    hist_file = ROOT / "release/history.json"
    data = {"releases": []}
    if hist_file.is_file():
        try:
            data = json.loads(hist_file.read_text(encoding="utf-8"))
        except Exception:
            pass
    
    record = {
        "version": version,
        "build_number": build_number,
        "platform": platform,
        "target": target,
        "timestamp": subprocess.check_output(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"]).decode().strip(),
    }
    data["releases"].append(record)
    hist_file.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description="Hayat Simülasyonu Yerel Yayın Otomasyonu")
    parser.add_argument("version", help="Sürüm adı (örn: 1.0.0)")
    parser.add_argument("--testflight", action="store_true", help="iOS IPA üret ve TestFlight'a yükle")
    parser.add_argument("--ios-build-number", type=int, default=1, help="iOS Build numarası (varsayılan: 1)")
    parser.add_argument("--skip-checks", action="store_true", help="Testleri ve analiz kontrollerini atla")
    parser.add_argument("--dry-run", action="store_true", help="Yükleme yapmadan yalnızca derle ve doğrula")
    args = parser.parse_args()

    if not re.fullmatch(r"\d+\.\d+\.\d+", args.version):
        fail("Sürüm numarası semver formatında olmalıdır (örn: 1.0.0).")

    notes_text, notes_path = verify_notes(args.version, "ios")
    config = load_config()

    if not args.skip_checks:
        run_quality_checks()

    export_plist = config.get("IOS_EXPORT_OPTIONS_PLIST")
    if not export_plist or not Path(export_plist).is_file():
        fail(f"ExportOptions.plist bulunamadı: {export_plist}")

    ipa_path = build_ios_ipa(args.version, args.ios_build_number, export_plist)

    if args.dry_run:
        log(f"[DRY-RUN] IPA başarıyla oluşturuldu: {ipa_path}. Yükleme atlandı.")
        return

    if args.testflight:
        upload_to_testflight(ipa_path, notes_path, config)
        update_history(args.version, args.ios_build_number, "ios", "testflight")
        log(f"Tebrikler! Sürüm {args.version} ({args.ios_build_number}) TestFlight'a başarıyla gönderildi.")


if __name__ == "__main__":
    main()
