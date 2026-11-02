#!/usr/bin/env python3
"""Local release orchestration. Credentials stay outside the repository."""
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
CONFIG = Path.home() / ".config/life-simulation/release.env"
STEPS = {"android": "Android", "ios": "iOS"}


def fail(message):
    raise RuntimeError(message)


def run(args, *, env=None):
    print("+", " ".join(str(a) for a in args), flush=True)
    subprocess.run([str(a) for a in args], cwd=ROOT, env=env, check=True)


def config():
    if not CONFIG.is_file():
        return {}
    values = {}
    for line in CONFIG.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            fail(f"Geçersiz ayar satırı: {CONFIG}")
        key, value = line.split("=", 1)
        key = key.strip()
        if not re.fullmatch(r"[A-Z][A-Z0-9_]*", key):
            fail(f"Geçersiz ayar adı: {key}")
        values[key] = value.strip().strip('"').strip("'")
    return values


def require_file(value, label):
    if not value or not Path(value).expanduser().is_file():
        fail(f"{label} bulunamadı. {CONFIG} dosyasını kontrol et.")
    return str(Path(value).expanduser().resolve())


def notes(path, limit, label):
    if not path.is_file():
        fail(f"{label} sürüm notu eksik: {path}")
    content = path.read_text(encoding="utf-8").strip()
    if not content:
        fail(f"{label} sürüm notu boş: {path}")
    if len(content) > limit:
        fail(f"{label} sürüm notu {len(content)} karakter; sınır {limit}: {path}")
    return content


def project_identifiers():
    gradle = (ROOT / "android/app/build.gradle.kts").read_text(encoding="utf-8")
    android = set(re.findall(r'^\s*applicationId\s*=\s*"([^"]+)"', gradle, re.M))
    project = (ROOT / "ios/Runner.xcodeproj/project.pbxproj").read_text(encoding="utf-8")
    ios = set(re.findall(r'^\s*PRODUCT_BUNDLE_IDENTIFIER\s*=\s*([^;]+);', project, re.M))
    ios = {value.strip().strip('"') for value in ios if not value.strip().strip('"').endswith(".RunnerTests")}
    if len(android) != 1 or len(ios) != 1:
        fail("Android applicationId veya iOS bundle ID tek ve açık değil; hedefi elle doğrula.")
    return android.pop(), ios.pop()


def main():
    parser = argparse.ArgumentParser(
        description="Hayat Simülasyonu yerel mağaza sürümü",
        epilog="Örnekler: ./scripts/release.sh 1.2.3 --dry-run | ./scripts/release.sh 1.2.3 --android --track internal | ./scripts/release.sh 1.2.3 --testflight",
    )
    parser.add_argument("version", help="Örn. 1.2.3")
    platform = parser.add_mutually_exclusive_group()
    platform.add_argument("--android", action="store_true")
    platform.add_argument("--ios", action="store_true")
    platform.add_argument("--testflight", action="store_true")
    parser.add_argument("--track", choices=["internal", "alpha", "beta", "production"], default="internal")
    parser.add_argument("--release-status", choices=["draft", "completed"], default="draft")
    parser.add_argument("--android-build-number", type=int)
    parser.add_argument("--ios-build-number", type=int)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--git-record", action="store_true", help="Başarıdan sonra yalnız sürüm dosyalarını commit/tag yap")
    args = parser.parse_args()
    if not re.fullmatch(r"\d+\.\d+\.\d+", args.version):
        fail("Sürüm 1.2.3 biçiminde olmalı.")
    if args.track != "internal" and (args.ios or args.testflight):
        fail("--track yalnız Android ile kullanılabilir; --android ekle.")
    if args.release_status != "draft" and (args.ios or args.testflight):
        fail("--release-status yalnız Android ile kullanılabilir.")
    if args.testflight and args.android_build_number:
        fail("--testflight ile --android-build-number birlikte kullanılamaz.")
    if args.android and args.ios_build_number:
        fail("--android ile --ios-build-number birlikte kullanılamaz.")
    if args.ios and args.android_build_number:
        fail("--ios ile --android-build-number birlikte kullanılamaz.")
    if args.git_record and args.dry_run:
        fail("--git-record ve --dry-run birlikte kullanılamaz.")
    for value in (args.android_build_number, args.ios_build_number):
        if value is not None and value < 1:
            fail("Build numarası pozitif olmalı.")

    targets = ["android"] if args.android else ["ios"] if (args.ios or args.testflight) else ["android", "ios"]
    mode = "testflight" if args.testflight else "app_store"
    app_android, app_ios = project_identifiers()
    settings = config()
    pubspec = ROOT / "pubspec.yaml"
    source = pubspec.read_text(encoding="utf-8")
    match = re.search(r"^version: (\d+\.\d+\.\d+)\+(\d+)\s*$", source, re.M)
    if not match:
        fail("pubspec.yaml version: x.y.z+N biçiminde değil.")
    default_number = int(match.group(2)) + (1 if args.version != match.group(1) else 0)
    release_dir = ROOT / "dist/releases" / args.version
    state_file = release_dir / "state.json"
    state = json.loads(state_file.read_text()) if state_file.is_file() else {}
    numbers = {}
    for target in targets:
        explicit = getattr(args, target + "_build_number")
        prior = state.get(target, {}).get("build_number")
        numbers[target] = explicit or prior or default_number
        if prior and numbers[target] != prior:
            fail(f"{target} için kayıtlı build numarası {prior}; farklı numarayla devam edilemez.")
        status = state.get(target, {}).get("status")
        if status == "uploaded" and not args.dry_run:
            fail(f"{target} build {prior} zaten yüklendi. Aynı sürümde diğer platformu ayrı çalıştır.")
        if status == "attempted" and not args.dry_run:
            fail(f"{target} yüklemesinin sonucu belirsiz. Mağazada build {prior} durumunu kontrol et; state.json kaydını elle uzlaştır.")
    print(f"Hedef: {', '.join(STEPS[t] for t in targets)} | sürüm {args.version} | build: {numbers}")
    print(f"Android: {args.track}/{args.release_status} | iOS: {mode} | dry-run: {args.dry_run}")
    if args.track == "production" or args.release_status == "completed":
        print("UYARI: production/completed gerçek kullanıcılara dağıtım başlatabilir.")
    print("Aşamalar: ön kontrol → pub get/analyze/test → imzalı build → " + ("yükleme yok" if args.dry_run else "Fastlane yükleme"))
    if args.git_record:
        print("Başarılı olursa yerel commit/tag oluşturulacak; push yapılmayacak.")
    for target in targets:
        notes(ROOT / "release_notes" / args.version / (target + ".txt"), 500 if target == "android" else 4000, STEPS[target])
    if settings.get("ANDROID_PACKAGE") != app_android and "android" in targets:
        fail(f"{CONFIG} içinde ANDROID_PACKAGE={app_android} açıkça tanımlanmalı; Play uygulamasını doğrula.")
    if settings.get("IOS_BUNDLE_ID") != app_ios and "ios" in targets:
        fail(f"{CONFIG} içinde IOS_BUNDLE_ID={app_ios} açıkça tanımlanmalı; App Store uygulamasını doğrula.")
    for cmd in ["flutter", "dart", "java", "bundle"] + (["keytool", "jarsigner"] if "android" in targets else []) + (["xcodebuild", "xcrun"] if "ios" in targets else []):
        if not shutil.which(cmd):
            fail(f"Gerekli araç yok: {cmd}")
    if "android" in targets:
        sdk = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
        local_properties = ROOT / "android/local.properties"
        if not (sdk and Path(sdk).is_dir()) and not local_properties.is_file():
            fail("Android SDK bulunamadı; ANDROID_HOME veya android/local.properties ayarla.")
        props = ROOT / "android/key.properties"
        if not props.is_file():
            fail("android/key.properties yok; debug anahtarıyla release yapılamaz.")
        lines = props.read_text().splitlines()
        values = dict(line.split("=", 1) for line in lines if "=" in line and not line.lstrip().startswith("#"))
        for key in ("storeFile", "storePassword", "keyAlias", "keyPassword"):
            if not values.get(key):
                fail(f"android/key.properties içinde {key} eksik.")
        if not (ROOT / "android/app" / values["storeFile"]).is_file():
            fail("Android upload keystore bulunamadı.")
        keystore = ROOT / "android/app" / values["storeFile"]
        cert = subprocess.run(
            ["keytool", "-exportcert", "-keystore", str(keystore), "-alias", values["keyAlias"], "-storepass:env", "RELEASE_STORE_PASS"],
            env={**os.environ, "RELEASE_STORE_PASS": values["storePassword"]}, capture_output=True
        )
        if cert.returncode or not cert.stdout:
            fail("Upload keystore/alias doğrulanamadı; key.properties bilgilerini kontrol et.")
        debug_store = Path.home() / ".android/debug.keystore"
        if debug_store.is_file():
            debug_cert = subprocess.run(
                ["keytool", "-exportcert", "-keystore", str(debug_store), "-alias", "androiddebugkey", "-storepass", "android"],
                capture_output=True
            )
            if debug_cert.returncode == 0 and cert.stdout == debug_cert.stdout:
                fail("Release keystore debug anahtarıyla aynı; mağaza build'i durduruldu.")
        if not args.dry_run:
            settings["PLAY_JSON_KEY"] = require_file(settings.get("PLAY_JSON_KEY"), "Play servis hesabı")
    if "ios" in targets:
        plist = require_file(settings.get("IOS_EXPORT_OPTIONS_PLIST"), "iOS App Store ExportOptions.plist")
        try:
            with open(plist, "rb") as file:
                export_options = plistlib.load(file)
        except (OSError, ValueError) as exc:
            fail(f"ExportOptions.plist okunamadı: {exc}")
        if export_options.get("method") not in ("app-store", "app-store-connect"):
            fail("ExportOptions.plist method App Store dağıtımı için app-store-connect olmalı.")
        if not args.dry_run:
            for key in ("ASC_KEY_ID", "ASC_ISSUER_ID"):
                if not settings.get(key):
                    fail(f"{key} eksik: {CONFIG}")
            settings["ASC_KEY_FILE"] = require_file(settings.get("ASC_KEY_FILE"), "App Store Connect API anahtarı")
        if subprocess.run(["xcodebuild", "-version"], capture_output=True).returncode:
            fail("Xcode çalışmıyor.")
    if not args.dry_run and subprocess.run(["bundle", "check"], cwd=ROOT, capture_output=True).returncode != 0:
        fail("Fastlane gemleri eksik. Önce bundle install çalıştır.")
    if args.git_record:
        intended = {"pubspec.yaml"} | {f"release_notes/{args.version}/{t}.txt" for t in targets}
        changes = subprocess.run(["git", "status", "--porcelain", "--untracked-files=all"], cwd=ROOT, capture_output=True, text=True, check=True).stdout.splitlines()
        unrelated = [line for line in changes if line[3:] not in intended]
        if unrelated:
            fail("--git-record için sürüm dosyaları dışındaki çalışma ağacı temiz olmalı; mevcut değişiklikler korunuyor.")
        if any(line[3:] == "pubspec.yaml" for line in changes):
            fail("--git-record öncesinde pubspec.yaml içindeki mevcut değişikliği ayrı kaydet.")
        for tag in [f"v{args.version}-{t}" for t in targets]:
            if subprocess.run(["git", "tag", "-l", tag], cwd=ROOT, capture_output=True, text=True).stdout.strip():
                fail(f"Git etiketi zaten var: {tag}")

    stage = "kalite kontrolleri"
    try:
        run(["flutter", "pub", "get"])
        run(["flutter", "analyze"])
        run(["flutter", "test"])
        for target in targets:
            number = numbers[target]
            stage = f"{target} build"
            symbols = release_dir / target / str(number) / "symbols"
            symbols.mkdir(parents=True, exist_ok=True)
            common = [f"--build-name={args.version}", f"--build-number={number}", "--release", "--dart-define=MONETIZATION_LIVE=false", "--dart-define=AD_TEST_MODE=false", "--obfuscate", f"--split-debug-info={symbols}"]
            if target == "android":
                run(["flutter", "build", "appbundle", *common])
                origin = ROOT / "build/app/outputs/bundle/release/app-release.aab"
                suffix = "aab"
            else:
                run(["flutter", "build", "ipa", *common, f"--export-options-plist={plist}"])
                candidates = list((ROOT / "build/ios/ipa").glob("*.ipa"))
                if len(candidates) != 1:
                    fail("IPA bulunamadı veya birden fazla IPA var.")
                origin = candidates[0]
                suffix = "ipa"
            if not origin.is_file() or origin.stat().st_size == 0:
                fail(f"{target} çıktısı bulunamadı: {origin}")
            artifact = release_dir / target / str(number) / f"life-simulation-{args.version}+{number}.{suffix}"
            shutil.copy2(origin, artifact)
            if target == "android":
                run(["jarsigner", "-verify", "-strict", str(artifact)])
                mapping = ROOT / "build/app/outputs/mapping/release/mapping.txt"
                if mapping.is_file():
                    shutil.copy2(mapping, artifact.parent / "mapping.txt")
            print(f"{target} build başarılı: {artifact}")
            if args.dry_run:
                print(f"{target} dry-run: mağazaya yüklenmedi.")
                continue
            stage = f"{target} Fastlane yüklemesi"
            metadata = release_dir / target / str(number) / "metadata"
            metadata.mkdir(parents=True, exist_ok=True)
            note_path = ROOT / "release_notes" / args.version / (target + ".txt")
            if target == "android":
                changelog = metadata / "tr-TR/changelogs" / f"{number}.txt"
                changelog.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(note_path, changelog)
                lane = ["android", "release", f"aab:{artifact}", f"track:{args.track}", f"status:{args.release_status}", f"metadata:{metadata}"]
            else:
                lane = ["ios", "beta_upload" if mode == "testflight" else "app_store", f"ipa:{artifact}", f"notes:{note_path}", f"metadata:{metadata}"]
                if mode == "app_store":
                    lane.append(f"version:{args.version}")
            state[target] = {"build_number": number, "status": "attempted", "artifact": str(artifact), "destination": args.track if target == "android" else mode}
            state_file.parent.mkdir(parents=True, exist_ok=True)
            state_file.write_text(json.dumps(state, indent=2) + "\n")
            run(["bundle", "exec", "fastlane", *lane], env={**os.environ, **settings, "FASTLANE_SKIP_UPDATE_CHECK": "1"})
            state[target]["status"] = "uploaded"
            state_file.write_text(json.dumps(state, indent=2) + "\n")
            print(f"{target} yükleme başarılı; mağazada işlenme durumunu ayrıca kontrol et.")
        if not args.dry_run:
            new_number = max(int(match.group(2)) if args.version == match.group(1) else 0, *numbers.values())
            pubspec.write_text(source[:match.start()] + f"version: {args.version}+{new_number}" + source[match.end():], encoding="utf-8")
            if args.git_record:
                tags = [f"v{args.version}-{t}" for t in targets]
                files = [str(pubspec.relative_to(ROOT))] + [str((ROOT / "release_notes" / args.version / (t + ".txt")).relative_to(ROOT)) for t in targets]
                run(["git", "add", "--", *files])
                run(["git", "commit", "-m", f"Release {args.version}", "--", *files])
                for tag in tags:
                    run(["git", "tag", tag])
                print(f"Yerel commit ve {', '.join(tags)} oluşturuldu; push yapılmadı.")
    except (subprocess.CalledProcessError, RuntimeError) as exc:
        fail(f"{stage} başarısız: {exc}. Yükleme denendiyse {state_file} ve mağaza durumunu kontrol et.")
    print(f"Tamamlandı: {args.version}. Kayıt: {state_file if not args.dry_run else 'dry-run kaydı yok'}")


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as exc:
        print(f"HATA: {exc}", file=sys.stderr)
        sys.exit(1)
