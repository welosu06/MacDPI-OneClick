#!/bin/bash
set -e

ROOT="$HOME/.macdpi-oneclick"
DIR="$ROOT/MacDPI"

clear
echo "MacDPI OneClick kaldırılacak."
read -r -p "Devam edilsin mi? [e/H] " ans
case "${ans:-H}" in
  e|E|y|Y) ;;
  *) exit 0 ;;
esac

if [ -d "$DIR" ]; then
  cd "$DIR"
  ./ServiceRemove.sh || true
fi

if [ -d "$ROOT" ]; then
  mv "$ROOT" "$HOME/.Trash/macdpi-oneclick-$(date +%Y%m%d-%H%M%S)"
fi

for f in DPI_Ac.command DPI_Kapat.command Kaldir.command Durum.command; do
  [ -e "$HOME/Desktop/$f" ] && mv "$HOME/Desktop/$f" "$HOME/.Trash/" || true
done

echo
echo "MacDPI OneClick kaldırıldı ve dosyalar Çöp Kutusu'na taşındı."
echo "Homebrew, Go ve Xcode Command Line Tools kaldırılmadı."
read -r -p "Kapatmak için Enter'a bas..." _ || true
