#!/bin/bash
set -e

DIR="$HOME/.macdpi-oneclick/MacDPI"

if [ ! -d "$DIR" ]; then
  echo "MacDPI OneClick kurulu değil."
  read -r -p "Kapatmak için Enter'a bas..." _ || true
  exit 0
fi

cd "$DIR"
./ServiceRemove.sh

echo
echo "DPI KAPALI"
echo "Tekrar açmak için DPI_Ac.command dosyasını çalıştır."
sleep 2
