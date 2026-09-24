#!/bin/bash
set -u

ROOT="$HOME/.macdpi-oneclick"
DIR="$ROOT/MacDPI"
LABEL="com.macdpi"
SAFETY="$ROOT/launcher/NetworkSafety.sh"

[ -f "$SAFETY" ] || { echo "NetworkSafety.sh bulunamadı / missing."; exit 1; }
# shellcheck source=/dev/null
source "$SAFETY"
acquire_lock || exit 1
trap 'release_lock >/dev/null 2>&1 || true' EXIT

if [ ! -d "$DIR" ]; then
  echo "MacDPI kurulu değil / MacDPI is not installed."
  exit 1
fi

if service_loaded; then
  echo "DPI zaten aktif / DPI is already active."
  if internet_ok; then
    echo "İnternet sağlık kontrolü: OK / Internet health: OK"
    exit 0
  fi
  echo "Servis aktif görünüyor ancak internet testi başarısız."
  echo "Service is loaded but the internet test failed."
  echo "Güvenli yeniden başlatma uygulanacak / A safe restart will be attempted."
  (cd "$DIR" && ./ServiceRemove.sh) || true
  restore_active_backup || true
fi

backup_current_network || exit 1
vpn_warning
captive_portal_warning
check_static_host_conflict

cd "$DIR"
sed -i '' 's/^MODE=.*/MODE=global/' settings.conf
sed -i '' 's/^BLOCK_QUIC=.*/BLOCK_QUIC=true/' settings.conf
sed -i '' 's/^MAX_CONN=.*/MAX_CONN=8192/' settings.conf

set +e
./ServiceInstall.sh
rc=$?
set -e

if [ "$rc" -ne 0 ]; then
  ./ServiceRemove.sh >/dev/null 2>&1 || true
  restore_active_backup || true
  verify_restored_network || true
  echo "DPI başlatılamadı; ağ geri alındı / DPI could not start; network was restored."
  exit "$rc"
fi

sleep 4
if ! internet_ok; then
  echo "Bağlantı sağlık testi başarısız / Connectivity health check failed."
  ./ServiceRemove.sh >/dev/null 2>&1 || true
  restore_active_backup || true
  verify_restored_network || true
  exit 1
fi

echo
echo "DPI AKTİF / DPI ACTIVE — GLOBAL MODE"
echo "İnternet sağlık kontrolü: OK / Internet health: OK"
osascript -e 'display notification "DPI aktif — sağlık kontrolü başarılı." with title "MacDPI OneClick"' >/dev/null 2>&1 || true
