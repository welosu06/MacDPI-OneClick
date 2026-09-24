#!/bin/bash
set -u

ROOT="$HOME/.macdpi-oneclick"
DIR="$ROOT/MacDPI"
SAFETY="$ROOT/launcher/NetworkSafety.sh"
OUT="$HOME/Desktop/MacDPI-Diagnostics-$(date +%Y%m%d-%H%M%S).txt"

[ -f "$SAFETY" ] && source "$SAFETY"

{
  echo "MacDPI OneClick Safe Diagnostics"
  echo "Generated: $(date)"
  echo "Version: $(cat "$ROOT/launcher/VERSION" 2>/dev/null || echo unknown)"
  echo "macOS: $(sw_vers -productVersion 2>/dev/null || echo unknown)"
  echo "Architecture: $(uname -m)"
  echo "Service loaded: $(launchctl print system/com.macdpi >/dev/null 2>&1 && echo yes || echo no)"
  echo "Internet health: $(internet_ok >/dev/null 2>&1 && echo OK || echo NOT_VERIFIED)"
  echo "Active interface: $(default_interface 2>/dev/null || echo unknown)"
  echo "Network service: $(active_network_service 2>/dev/null || echo unknown)"
  if [ -f "$DIR/settings.conf" ]; then
    echo
    echo "[settings]"
    grep -E '^(MODE|BLOCK_QUIC|MAX_CONN|DOH_SERVER)=' "$DIR/settings.conf" || true
  fi
  if [ -f "$ROOT/install-info.txt" ]; then
    echo
    echo "[install-info]"
    cat "$ROOT/install-info.txt"
  fi
  if [ -f "$DIR/logs/service.log" ]; then
    echo
    echo "[last service log lines]"
    tail -50 "$DIR/logs/service.log"
  fi
} | sanitize_stream > "$OUT"

echo "Tanılama dosyası oluşturuldu / Diagnostics file created:"
echo "$OUT"
echo
echo "IP adresleri ve kullanıcı ana klasörü otomatik maskelenir."
echo "IP addresses and the user home path are automatically redacted."
read -r -p "Menüye dönmek için Enter / Press Enter to return..." _ || true
