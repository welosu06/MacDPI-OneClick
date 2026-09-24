#!/bin/bash
set -u

DIR="$HOME/.macdpi-oneclick/MacDPI"
LABEL="com.macdpi"

clear
echo "MacDPI OneClick — Durum"
echo "======================="
echo

if [ ! -d "$DIR" ]; then
  echo "Kurulum: YOK"
else
  echo "Kurulum: VAR"
  echo "Konum: $DIR"
  if [ -f "$DIR/settings.conf" ]; then
    grep -E '^(MODE|BLOCK_QUIC|MAX_CONN|DOH_SERVER)=' "$DIR/settings.conf" || true
  fi
fi

echo
if sudo launchctl print "system/$LABEL" >/dev/null 2>&1; then
  echo "Servis: AKTİF"
else
  echo "Servis: KAPALI"
fi

if [ -f "$DIR/logs/service.log" ]; then
  echo
  echo "Son servis kayıtları:"
  tail -20 "$DIR/logs/service.log" || true
fi

echo
read -r -p "Kapatmak için Enter'a bas..." _ || true
