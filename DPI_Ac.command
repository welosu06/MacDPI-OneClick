#!/bin/bash
set -euo pipefail

DIR="$HOME/.macdpi-oneclick/MacDPI"
LABEL="com.macdpi"

if [ ! -d "$DIR" ]; then
  echo "MacDPI OneClick kurulu değil."
  echo "Önce Install.command dosyasını çalıştır."
  read -r -p "Kapatmak için Enter'a bas..." _ || true
  exit 1
fi

cd "$DIR"
sed -i '' 's/^MODE=.*/MODE=global/' settings.conf
sed -i '' 's/^BLOCK_QUIC=.*/BLOCK_QUIC=true/' settings.conf
sed -i '' 's/^MAX_CONN=.*/MAX_CONN=8192/' settings.conf

if sudo launchctl print "system/$LABEL" >/dev/null 2>&1; then
  ./ServiceRestart.sh
else
  ./ServiceInstall.sh
fi

echo
echo "DPI AKTİF — GLOBAL MOD"
osascript -e 'display notification "DPI aktif — Global mod" with title "MacDPI OneClick"' >/dev/null 2>&1 || true
sleep 2
