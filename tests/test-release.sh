#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
for file in *.command *.sh scripts/*.sh tests/*.sh; do /bin/bash -n "$file"; done
test "$(cat VERSION)" = 1.6.1

git clone -q --no-hardlinks "${MACDPI_TEST_UPSTREAM:-https://github.com/monotter/MacDPI.git}" "$TMP/upstream"
git -C "$TMP/upstream" checkout -q 30556c5dd90d23819e32b4c2bfb8b8b670cde8a4
/bin/bash ApplyFixes.sh "$TMP/upstream"
git -C "$TMP/upstream" diff > "$TMP/first.patch"
/bin/bash ApplyFixes.sh "$TMP/upstream"
git -C "$TMP/upstream" diff > "$TMP/second.patch"
cmp "$TMP/first.patch" "$TMP/second.patch"
grep -q '"stack": "gvisor"' "$TMP/upstream/core/GenConfig.sh"
grep -q '^CIADPI_ARGS="-I 0.0.0.0 --split 2"$' "$TMP/upstream/settings.conf"
grep -q 'export MACDPI_BIND_INTERFACE' "$TMP/upstream/core/RunDPI.sh"
grep -q 'git -C "$BYEDPI_DIR" apply --check' "$TMP/upstream/bin/Build.sh"
test "$(cat "$TMP/upstream/oneclick-runtime-version")" = 1.6.1
/bin/bash tests/test-boot.sh "$TMP/upstream"

git init -q "$TMP/wrong-revision"
git -C "$TMP/wrong-revision" -c user.name=Test -c user.email=test@example.invalid commit -q --allow-empty -m test
if /bin/bash ApplyFixes.sh "$TMP/wrong-revision"; then echo 'Wrong revision accepted' >&2; exit 1; fi

git clone -q --no-hardlinks "${MACDPI_TEST_BYEDPI:-https://github.com/hufrea/byedpi.git}" "$TMP/byedpi"
git -C "$TMP/byedpi" checkout -q ba532298de7b28cfe854aea83d061369d13ca290
git -C "$TMP/byedpi" apply --check "$ROOT/patches/byedpi-macos-interface.patch"
git -C "$TMP/byedpi" apply "$ROOT/patches/byedpi-macos-interface.patch"
make -s -C "$TMP/byedpi"
"$TMP/byedpi/ciadpi" --version
python3 tests/test_proxy_binding.py "$TMP/byedpi/ciadpi"

# Lock release must not erase another operation's lock.
export MACDPI_ROOT="$TMP/state"
source ./NetworkSafety.sh
acquire_lock
release_lock
test ! -d "$LOCK_DIR"
mkdir -p "$LOCK_DIR"
printf '%s\n' not-our-pid > "$LOCK_DIR/pid"
release_lock
test -d "$LOCK_DIR"

# A newly extracted release must select itself, even with an older installation.
mkdir -p "$TMP/home/.macdpi-oneclick/launcher" "$TMP/package" "$TMP/Desktop"
printf '1.5.0\n' > "$TMP/home/.macdpi-oneclick/launcher/VERSION"
touch "$TMP/home/.macdpi-oneclick/launcher/Install.command"
cp VERSION Install.command "$TMP/package/"
sed '/^GREEN=/,$d' MacDPI.command | sed 's|ROOT="$HOME/.macdpi-oneclick"|ROOT="${MACDPI_TEST_HOME}/.macdpi-oneclick"|' > "$TMP/package/select.command"
printf '\nprintf "%%s\\n" "$SCRIPT_DIR"\n' >> "$TMP/package/select.command"
test "$(MACDPI_TEST_HOME="$TMP/home" /bin/bash "$TMP/package/select.command")" = "$TMP/package"
cp "$TMP/package/select.command" "$TMP/Desktop/select.command"
test "$(MACDPI_TEST_HOME="$TMP/home" /bin/bash "$TMP/Desktop/select.command")" = "$TMP/home/.macdpi-oneclick/launcher"
echo 'Release regression checks passed.'
