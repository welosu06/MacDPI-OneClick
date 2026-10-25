# MacDPI OneClick v1.6.0

A bilingual installation and recovery menu for [MacDPI](https://github.com/monotter/MacDPI) on macOS.

**v1.6.0 fixes the Discord desktop “Update Failed / Retrying” case reproduced with v1.5.0.** It combines the gVisor TUN stack, a locally built ByeDPI patch that binds outbound sockets to the physical network interface, and the `--split 2` strategy. Installation and Repair now reapply these fixes instead of discarding them.

## Download and install

1. Open [Releases](https://github.com/welosu06/MacDPI-OneClick/releases/latest).
2. Download **MacDPI-OneClick-v1.6.0.zip**, then extract it.
3. Open **MacDPI.command** and choose **1 — Safe Install**.
4. If macOS blocks the launcher, use **Right-click → Open**, or **System Settings → Privacy & Security → Open Anyway** for the file you intentionally downloaded.
5. Enter your administrator password only in the normal macOS/sudo prompt. Compilation can take several minutes.
6. Use the **MacDPI OneClick.command** shortcut on the Desktop afterward.

Already using v1.5.0? Open the launcher **inside the newly extracted v1.6.0 folder** and select **1** once. The new package selects its own installer rather than the older installed copy. After the upgrade, option **5 — Repair** retains the v1.6.0 patches.

The release ZIP contains scripts and reviewable patches, not prebuilt third-party executables. The `.sha256` asset lets you check the download with `shasum -a 256 -c MacDPI-OneClick-v1.6.0.zip.sha256` from the download folder.

## Controls

| Option | Action |
| --- | --- |
| 1 | Install / upgrade this package |
| 2 | Enable DPI |
| 3 | Disable DPI and restore the saved network configuration |
| 4 | Health check, including native macOS TLS to the Discord updater |
| 5 | Repair using the installed package and its patches |
| 6 | Uninstall |
| 7 | Emergency network recovery |
| 8 | Create a redacted diagnostics report |
| 0 | Exit the menu |

Closing the menu does not stop the background service. Use **3** to stop it.

## What changed in v1.6.0

- **gVisor TUN:** the reproduced system-wide TLS failure disappeared when using gVisor together with physical-interface binding.
- **Physical-interface binding:** the ByeDPI patch uses macOS `IP_BOUND_IF` / `IPV6_BOUND_IF` for outbound sockets. A missing/invalid interface fails closed instead of silently sending desynchronized traffic back through TUN.
- **Native TLS strategy:** `-I 0.0.0.0 --split 2` passed both the ordinary curl and macOS SecureTransport tests in the reproduced environment. `--split 1` passed ordinary curl but failed the desktop updater.
- **DNS:** while active, the service points the active network service at `1.1.1.1`, allowing TUN's DNS interception to resolve through HTTPS. It flushes stale DNS entries. The previous network/DNS configuration is backed up for recovery.
- **IP configuration:** the runtime keeps the current DHCP/manual IP configuration by default instead of switching to a `.240` address.
- **Repair and upgrade:** the versioned patches are included in the installed launcher folder and applied after every pinned-source checkout.
- **Installer lock:** failure paths release their own operation lock before waiting for Enter; they cannot release another operation's lock.
- **Honest health checks:** general internet health and Discord updater HTTPS are reported separately. A reachable general website is not proof that Discord works.

## Verification and limits

The full fix was verified on the Apple Silicon Mac where the issue was reproduced: general HTTPS recovered, the native-TLS updater test returned HTTP 200 without disabling certificate checks, and Discord completed its downloads/installation and opened. This is not a guarantee for every ISP or network. Voice/UDP connectivity was not validated by that updater test.

The release checks shell syntax, clean patch application, repeated repair, revision rejection, actual local compilation of the patched proxy, loopback interface binding, invalid-interface rejection, launcher selection on upgrade, lock ownership and ZIP permissions. CI does not emulate the user's ISP or run a system-wide TUN.

The default bypass uses IPv4 sockets. IPv6-only networks, VPN default routes, managed networks, captive portals, and interfaces changing while the service runs need separate validation. If the network interface changes, disable and re-enable DPI. Intel is a build target; the reported end-to-end Discord verification was on Apple Silicon.

## Reproducible source

- MacDPI: `30556c5dd90d23819e32b4c2bfb8b8b670cde8a4`
- ByeDPI: `ba532298de7b28cfe854aea83d061369d13ca290`
- sing-box: `v1.13.14`
- Local patches: `patches/macdpi-runtime.patch` and `patches/byedpi-macos-interface.patch`

`ApplyFixes.sh` checks the MacDPI revision and refuses mismatched/partial patches. The patched build script verifies the ByeDPI revision and applies the interface patch before compiling. No machine-specific IP address or user path is embedded in the release.

## Recovery

Use **7 — Emergency Restore Network** if normal internet stops working. Backups are stored in `~/.macdpi-oneclick/network-backups/`; `active-backup` identifies the current recovery snapshot. Recovery may offer DHCP/automatic DNS only if a usable backup is unavailable and the user confirms.

This project is not Apple-notarized, operates no remote VPN server, and does not collect the administrator password. See [SECURITY.md](SECURITY.md), [CHANGELOG.md](CHANGELOG.md), and [Türkçe açıklama](README_TR.md). The wrapper is MIT-licensed; upstream projects retain their own licenses.
