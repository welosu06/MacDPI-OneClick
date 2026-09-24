#!/bin/bash
set -u

ROOT="$HOME/.macdpi-oneclick"
DIR="$ROOT/MacDPI"
SAFETY="$ROOT/launcher/NetworkSafety.sh"
VERSION="$(cat "$ROOT/launcher/VERSION" 2>/dev/null || echo "unknown")"

[ -f "$SAFETY" ] && source "$SAFETY"

clear
echo "MacDPI OneClick v$VERSION — Sağlık / Health"
echo "=========================================================="
echo

if [ -d "$DIR" ]; then
  echo "Kurulum / Installation: VAR / PRESENT"
  if [ -f "$DIR/settings.conf" ]; then
    echo "Yapılandırma / Configuration:"
    grep -E '^(MODE|BLOCK_QUIC|MAX_CONN|DOH_SERVER)=' "$DIR/settings.conf" || true
  fi
else
  echo "Kurulum / Installation: YOK / NOT INSTALLED"
fi

echo
if launchctl print system/com.macdpi >/dev/null 2>&1; then
  echo "Servis / Service: AKTİF / ACTIVE"
else
  echo "Servis / Service: KAPALI / OFF"
fi

if type internet_ok >/dev/null 2>&1 && internet_ok; then
  echo "İnternet / Internet: OK"
else
  echo "İnternet / Internet: DOĞRULANAMADI / NOT VERIFIED"
fi

echo "Aktif arayüz / Active interface: $(default_interface 2>/dev/null || echo unknown)"
echo "Ağ servisi / Network service: $(active_network_service 2>/dev/null || echo unknown)"

if [ -f "$ROOT/active-backup" ]; then
  b="$(cat "$ROOT/active-backup" 2>/dev/null || true)"
  if [ -f "$b/created_at" ]; then
    echo "Son temiz yedek / Last clean backup: $(cat "$b/created_at")"
  fi
fi

if [ -f "$DIR/logs/service.log" ]; then
  echo
  echo "Son servis kayıtları (kişisel ağ adresleri maskelenir):"
  echo "Recent service logs (network addresses are redacted):"
  tail -15 "$DIR/logs/service.log" | sanitize_stream || true
fi

echo
read -r -p "Menüye dönmek için Enter / Press Enter to return..." _ || true
