#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/welosu06/MacDPI-OneClick.git"
TARGET="$HOME/.macdpi-oneclick-installer"

echo "MacDPI OneClick indiriliyor..."
rm -rf "$TARGET"
git clone --depth 1 "$REPO_URL" "$TARGET"

cd "$TARGET"
chmod +x ./*.command

echo
echo "Kurulum başlatılıyor..."
exec /bin/bash ./Install.command
