# MacDPI OneClick v1.5.0

**System-wide MacDPI control for macOS with a beginner-friendly menu, automatic recovery, network health checks and transparent local builds.**

MacDPI OneClick is an unofficial safety/control layer around [MacDPI](https://github.com/monotter/MacDPI). It is designed for Apple Silicon and Intel Macs and gives users one bilingual terminal menu for installation, enable/disable, health checks, repair, recovery, diagnostics and uninstall.

> This project changes system networking. v1.5.0 is designed to reduce the chance that a failed activation leaves the Mac with a broken network configuration, but no networking tool can guarantee compatibility with every router, VPN, managed network, captive portal, ISP or future macOS release.

## Quick Start

1. Open the [latest release](https://github.com/welosu06/MacDPI-OneClick/releases/latest).
2. Download **MacDPI-OneClick-v1.5.0.zip** from **Assets**.
3. Extract the ZIP.
4. Double-click **MacDPI.command**.
5. If macOS blocks the file, first try **Right-click → Open → Open**.
6. If it is still blocked, open **System Settings → Privacy & Security**, scroll to the security message for the blocked launcher, choose **Open Anyway**, then confirm **Open**.
7. When the Control Center opens, type **1** and press **Enter** for the first installation.
8. Enter the Mac administrator password if macOS requests it. The wrapper scripts do **not** read, save or log that password.
9. After installation, use the **MacDPI OneClick.command** shortcut created on the Desktop.

> Download the ZIP from **Releases / Assets**. The release package is built on a macOS GitHub Actions runner and checked to preserve executable permissions for the `.command` launchers.

## Control Center

| Option | Action |
| --- | --- |
| **1** | Safe Install |
| **2** | Enable DPI |
| **3** | Disable DPI and restore the saved clean network configuration |
| **4** | Health Check |
| **5** | Repair Installation |
| **6** | Uninstall Completely |
| **7** | Emergency Restore Network |
| **8** | Create a Redacted Diagnostics Report |
| **0** | Exit |

Closing Terminal does **not** disable an already installed MacDPI launch daemon. Use option **3** when you intentionally want to stop DPI and return to the saved normal network configuration.

## v1.5.0 Safety Model

### 1. A fresh clean-network backup before activation

Before MacDPI is enabled, MacDPI OneClick records the currently active network configuration. The backup includes:

- active macOS network service;
- DHCP or manual-IP mode;
- IP address;
- subnet mask;
- router/gateway;
- DNS configuration;
- active interface and, when macOS exposes it, the Wi-Fi network name.

Backups are stored under:

`~/.macdpi-oneclick/network-backups/`

The currently relevant recovery backup is referenced by:

`~/.macdpi-oneclick/active-backup`

A new clean backup is made before a new activation instead of relying indefinitely on one old network snapshot. Older backups are automatically pruned to keep the backup history bounded.

### 2. Upgrade protection for v1.3/v1.4 users

Earlier releases used a single legacy backup directory:

`~/.macdpi-oneclick/network-backup`

v1.5.0 detects that format and imports it into the new backup system before an existing MacDPI service is touched. This is intended to preserve recovery information during upgrades.

### 3. `.240` address conflict handling

Upstream MacDPI may attempt to use a temporary LAN address ending in `.240`. v1.5.0 checks that candidate first.

If the address appears occupied, MacDPI OneClick does **not** deliberately force it. The user receives a warning, upstream MacDPI is allowed to continue if it can operate without successfully applying that static address, and a real connectivity health check is then used to decide whether the activation is safe to keep.

If connectivity is unhealthy, the service is stopped and the saved clean network configuration is restored automatically.

### 4. Connectivity health checks and rollback

After installation or activation, MacDPI OneClick checks internet reachability using multiple HTTPS endpoints. If the health check fails:

1. the MacDPI service is stopped;
2. the saved clean network configuration is restored;
3. DNS caches are refreshed;
4. normal internet connectivity is checked again.

This rollback path is also used after certain activation failures.

### 5. Emergency Restore Network

Option **7 — Emergency Restore Network** is intentionally separate from normal disable/uninstall flows. It is designed for the case where the user only wants the network returned to a known clean state.

It attempts to:

- stop/remove the MacDPI service;
- restore the latest clean backup;
- refresh DNS caches;
- verify normal connectivity.

If no usable backup exists, it can offer to return the currently active network service to DHCP with automatic DNS as a last-resort recovery step. That fallback is intentionally user-confirmed because a manually configured corporate/static network may legitimately require manual settings.

### 6. VPN / Private Relay / managed-network awareness

If a `utun` interface is detected, the user receives a warning because VPN software, Private Relay and other system networking features can use these interfaces. The presence of `utun` alone is **not** treated as proof of a problem; the post-activation health check remains the deciding safety signal.

The installer also checks for signs of a captive-portal network and warns the user to complete Wi-Fi sign-in first when appropriate.

### 7. Operation lock

Install, enable, disable, recovery and uninstall operations use a lock so two network-changing MacDPI operations are not intentionally run at the same time. Stale locks are detected and cleaned when the recorded process is no longer running.

### 8. Safer Repair behavior

The Repair option can run from the installed launcher directory. v1.5.0 avoids copying launcher files onto themselves, preventing the earlier self-copy failure mode.

Repair rebuilds/reinstalls the currently packaged wrapper and pinned MacDPI configuration. It is not described as an automatic online self-updater for the wrapper itself.

### 9. Redacted diagnostics

Option **8** creates a text diagnostics file on the Desktop. It includes useful technical state such as:

- MacDPI OneClick version;
- macOS version and CPU architecture;
- service loaded/not-loaded state;
- connectivity health result;
- safe MacDPI configuration values;
- recent service log lines.

Before the report is written, the helper masks IPv4/IPv6-like addresses and replaces the user's home-directory path. Users should still review any diagnostics file before posting it publicly.

### 10. Uninstall cleanup

Uninstall attempts to restore the saved network state first, then removes the MacDPI launch daemon and checks whether the service is still registered. The MacDPI OneClick working directory and Desktop launchers are moved to the Trash.

Homebrew, Go and Apple Command Line Tools are intentionally left installed because they may be used by other software.

## What MacDPI changes while active

The upstream stack may:

- create/use a TUN-based routing path;
- run sing-box locally;
- run ByeDPI/ciadpi locally;
- temporarily change network IP configuration;
- temporarily change DNS;
- block QUIC/UDP 443 so traffic can fall back to TCP where the DPI desynchronization strategy applies;
- install the system launch daemon `com.macdpi`;
- automatically run that daemon at boot.

## Source pinning and local builds

MacDPI is pinned to the reviewed upstream commit:

`30556c5dd90d23819e32b4c2bfb8b8b670cde8a4`

The pinned MacDPI build script in turn uses:

- ByeDPI/ciadpi ref `ba53229`;
- sing-box `v1.13.14`.

The project does not bundle opaque prebuilt copies of those third-party binaries in its release ZIP. They are built locally during installation from the upstream sources defined by the pinned MacDPI version.

Commit pinning improves reproducibility and prevents a released wrapper from silently following future MacDPI `main` changes. It is not the same as a cryptographically signed upstream release: the pinned MacDPI commit currently used by this project is not GPG-verified on GitHub.

## Privacy and administrator privileges

The wrapper scripts intentionally contain no telemetry collector and do not operate a remote VPN server. The administrator password is handled by macOS `sudo`; the wrapper does not read or store it.

During installation, network access is naturally required to retrieve dependencies/source code from services such as GitHub and, when needed, the official Homebrew installer.

Administrator privileges are necessary because network configuration and a system launch daemon cannot be managed as an ordinary unprivileged process.

## Gatekeeper / “Apple could not verify…”

MacDPI OneClick is currently not distributed with Apple Developer ID signing/notarization. Depending on macOS security settings, the first launch can therefore require manual approval:

**Preferred first attempt:**

`Right-click MacDPI.command → Open → Open`

**If macOS still blocks it:**

`System Settings → Privacy & Security → Open Anyway → Open`

Only approve a file you intentionally downloaded from this repository's release page.

## Compatibility notes

The scripts are designed for:

- Apple Silicon (`arm64`, including M-series Macs);
- Intel (`x86_64`) Macs.

Network behavior can differ on VPNs, managed/company networks, manually configured static networks, captive portals, unusual router subnets and future macOS versions. The release workflow verifies shell syntax and package structure; it cannot emulate every real-world network configuration.

## Recovery order if something behaves unexpectedly

1. Open **MacDPI OneClick.command** from the Desktop.
2. Choose **7 — Emergency Restore Network** if your priority is restoring normal networking.
3. After connectivity returns, use **4 — Health Check**.
4. If you no longer want the software, choose **6 — Uninstall Completely**.
5. If macOS networking still needs manual attention, use **System Settings → Network** to review the affected service.

## Security documentation and changes

See [SECURITY.md](SECURITY.md) for the threat/recovery model and [CHANGELOG.md](CHANGELOG.md) for release changes.

Turkish beginner documentation: [README_TR.md](README_TR.md)

## Credits

MacDPI OneClick is an unofficial convenience and safety wrapper around the upstream MacDPI project. MacDPI, sing-box, ByeDPI and Homebrew remain projects of their respective maintainers and are governed by their own licenses and terms.

## License

The MacDPI OneClick wrapper scripts and documentation are licensed under the MIT License. Third-party components retain their own licenses.
