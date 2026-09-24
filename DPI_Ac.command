#!/bin/bash
set -u

ROOT="$HOME/.macdpi-oneclick"
DIR="$ROOT/MacDPI"
LABEL="com.macdpi"
SAFETY="$ROOT/launcher/NetworkSafety.sh"

if [ ! -d "$DIR" ]; then
  echo "MacDPI OneClick kurulu değil / MacDPI OneClick is not installed."
  echo "Önce menüden 1'i seç / First choose option 1 from the menu."
  read -r -p "Kapatmak için Enter'a bas / Press Enter to close..." _ || true
  exit 1
fi

if [ -f "$SAFETY" ]; then
  # shellcheck source=/dev/null
  source "$SAFETY"
fi

cd "$DIR"
sed -i '' 's/^MODE=.*/MODE=global/' settings.conf
sed -i '' 's/^BLOCK_QUIC=.*/BLOCK_QUIC=true/' settings.conf
sed -i '' 's/^MAX_CONN=.*/MAX_CONN=8192/' settings.conf

if type check_static_host_conflict >/dev/null 2>&1; then
  check_static_host_conflict || {
    echo "DPI açılmadı / DPI was not enabled."
    exit 1
  }
fi

set +e
if sudo launchctl print "system/$LABEL" >/dev/null 2>&1; then
  ./ServiceRestart.sh
  rc=$?
else
  ./ServiceInstall.sh
  rc=$?
fi
set -e

if [ "$rc" -ne 0 ]; then
  ./ServiceRemove.sh >/dev/null 2>&1 || true
  if type restore_network >/dev/null 2>&1; then
    restore_network "$ROOT/network-backup" || true
  fi
  echo "DPI başlatılamadı; ağ ayarları geri alındı / DPI could not start; network settings were restored."
  exit "$rc"
fi

sleep 4
if type internet_ok >/dev/null 2>&1 && ! internet_ok; then
  echo "Bağlantı testi başarısız; otomatik geri alma uygulanıyor."
  echo "Connectivity test failed; automatic rollback is being applied."
  ./ServiceRemove.sh >/dev/null 2>&1 || true
  restore_network "$ROOT/network-backup" || true
  exit 1
fi

echo
echo "DPI AKTİF / DPI ACTIVE — GLOBAL MODE"
echo "Bağlantı kontrolü başarılı / Connectivity check passed."
osascript -e 'display notification "DPI aktif — bağlantı kontrolü başarılı." with title "MacDPI OneClick"' >/dev/null 2>&1 || true
sleep 2
