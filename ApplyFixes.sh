#!/bin/bash
# Apply the reviewed OneClick patches to the pinned MacDPI checkout.
set -euo pipefail
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:?Usage: ApplyFixes.sh /path/to/MacDPI}"
TARGET="$(cd "$TARGET" && pwd)"
EXPECTED="30556c5dd90d23819e32b4c2bfb8b8b670cde8a4"
[ "$(git -C "$TARGET" rev-parse HEAD)" = "$EXPECTED" ] || {
  echo "Unexpected MacDPI revision; patches were not applied." >&2
  exit 1
}
PATCH="$SELF_DIR/patches/macdpi-runtime.patch"
if git -C "$TARGET" apply --check "$PATCH" 2>/dev/null; then
  git -C "$TARGET" apply "$PATCH"
elif git -C "$TARGET" apply --reverse --check "$PATCH" 2>/dev/null; then
  echo "Runtime patch already applied."
else
  echo "Runtime patch does not match this checkout; refusing partial repair." >&2
  exit 1
fi
cp -p "$SELF_DIR/patches/byedpi-macos-interface.patch" "$TARGET/bin/byedpi-macos-interface.patch"
sed -i '' 's/^CIADPI_ARGS=.*/CIADPI_ARGS="-I 0.0.0.0 --split 2"/' "$TARGET/settings.conf"
for file in Run.sh ServiceRemove.sh core/RunDPI.sh core/GenConfig.sh bin/Build.sh; do
  /bin/bash -n "$TARGET/$file"
done
printf '%s\n' '1.6.0' > "$TARGET/oneclick-runtime-version"
echo "OneClick 1.6.0 fixes applied: gVisor, physical-interface binding, split 2."
