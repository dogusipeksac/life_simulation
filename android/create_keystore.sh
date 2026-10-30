#!/usr/bin/env bash
# Bir kez: android/keystore/life_simulation.jks + key.properties üretir.
set -euo pipefail
cd "$(dirname "$0")"

STORE_FILE="keystore/life_simulation.jks"
ALIAS="life_simulation_key"
DNAME="${DNAME:-CN=Hayat Simulasyonu, OU=Mobile, O=Life Simulation, L=Istanbul, ST=Istanbul, C=TR}"

if [[ -z "${STORE_PASS:-}" || -z "${KEY_PASS:-}" ]]; then
  echo "Kullanım: STORE_PASS=... KEY_PASS=... ./create_keystore.sh"
  exit 1
fi

mkdir -p keystore

if [[ -f "$STORE_FILE" ]]; then
  echo "Zaten var: $STORE_FILE — silmeden yeniden üretmem."
  exit 1
fi

keytool -genkeypair -v \
  -keystore "$STORE_FILE" \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias "$ALIAS" \
  -storepass "$STORE_PASS" \
  -keypass "$KEY_PASS" \
  -dname "$DNAME"

cat > key.properties <<EOF
storePassword=$STORE_PASS
keyPassword=$KEY_PASS
keyAlias=$ALIAS
storeFile=../keystore/life_simulation.jks
EOF

echo "Tamam: $STORE_FILE ve key.properties hazır."
echo "Bu dosyalar git'e girmez. Şifreyi ve .jks yedeğini güvenli sakla."
echo "AAB: flutter build appbundle --release --dart-define=AD_TEST_MODE=false"
