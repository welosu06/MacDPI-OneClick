#!/bin/bash
set -e

ROOT="$HOME/.macdpi-oneclick"
DIR="$ROOT/MacDPI"
SAFETY="$ROOT/launcher/NetworkSafety.sh"

if [ ! -d "$DIR" ]; then
  echo "MacDPI OneClick kurulu değil / MacDPI OneClick is not installed."
  read -r -p "Kapatmak için Enter'a bas / Press Enter to close..." _ || true
  exit 0
fi

cd "$DIR"
/bin/bash ./ServiceRemove.sh || true

if [ -f "$SAFETY" ]; then
  # shellcheck source=/dev/null
  source "$SAFETY"
  restore_network "$ROOT/network-backup" || true
fi

echo
echo "DPI KAPALI / DPI OFF"
echo "Orijinal ağ ayarların geri yüklendi / Original network settings restored."
sleep 2
