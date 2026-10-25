#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION="$(cat VERSION)"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || exit 1
PACKAGE="MacDPI-OneClick-v$VERSION"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "dist" "$STAGE/$PACKAGE/patches"
cp VERSION MacDPI.command Install.command DPI_Ac.command DPI_Kapat.command \
  Durum.command Kaldir.command Agi_Kurtar.command Tani.command NetworkSafety.sh \
  ApplyFixes.sh README.md README_TR.md SECURITY.md CHANGELOG.md LICENSE \
  RELEASE_NOTES.md "$STAGE/$PACKAGE/"
cp patches/*.patch "$STAGE/$PACKAGE/patches/"
chmod 755 "$STAGE/$PACKAGE"/*.command "$STAGE/$PACKAGE"/*.sh
chmod 644 "$STAGE/$PACKAGE"/*.md "$STAGE/$PACKAGE/patches"/*.patch \
  "$STAGE/$PACKAGE/VERSION" "$STAGE/$PACKAGE/LICENSE"
COPYFILE_DISABLE=1 /usr/bin/ditto --norsrc -c -k --keepParent "$STAGE/$PACKAGE" "dist/$PACKAGE.zip"
mkdir "$STAGE/verify"
/usr/bin/ditto -x -k "dist/$PACKAGE.zip" "$STAGE/verify"
for file in "$STAGE/verify/$PACKAGE"/*.command "$STAGE/verify/$PACKAGE"/*.sh; do
  test -x "$file"
  /bin/bash -n "$file"
done
test -s "$STAGE/verify/$PACKAGE/patches/macdpi-runtime.patch"
test -s "$STAGE/verify/$PACKAGE/patches/byedpi-macos-interface.patch"
test "$(cat "$STAGE/verify/$PACKAGE/VERSION")" = "$VERSION"
(cd dist && shasum -a 256 "$PACKAGE.zip" > "$PACKAGE.zip.sha256")
echo "Built dist/$PACKAGE.zip and SHA-256 checksum."
