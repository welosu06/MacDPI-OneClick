# MacDPI OneClick

**One click. System-wide. Beginner-friendly. Fail-safe network rollback.**

MacDPI OneClick is a macOS installer and control center for [MacDPI](https://github.com/monotter/MacDPI). It provides a bilingual terminal menu, a Desktop shortcut and additional network-safety protections around MacDPI's global TUN mode.

> **Supported:** Apple Silicon (M1–M5 / arm64) and Intel Macs.

## Quick start

1. Open the [latest release](https://github.com/welosu06/MacDPI-OneClick/releases/latest).
2. Download **MacDPI-OneClick-v1.3.0.zip** from **Assets**.
3. Extract the ZIP.
4. Double-click **MacDPI.command**.
5. If macOS blocks it, right-click **MacDPI.command** → **Open** → **Open**.
6. First time? Type **1** and press **Enter**.
7. After installation, use the **MacDPI OneClick.command** shortcut created on your Desktop.

> Use the ZIP from **Releases / Assets**, not **Code → Download ZIP**. The release ZIP is built on macOS and verified to preserve executable permissions.

## Control Center

| Option | Action |
| --- | --- |
| 1 | Install MacDPI |
| 2 | Enable DPI bypass |
| 3 | Disable DPI bypass and restore the original network configuration |
| 4 | Check connection and service status |
| 5 | Update / repair the installation |
| 6 | Uninstall MacDPI OneClick and restore the original network configuration |
| 0 | Exit |

The terminal menu is shown in both Turkish and English.

## Safety protections

Before MacDPI changes networking, MacDPI OneClick saves the active network service's configuration under:

`~/.macdpi-oneclick/network-backup`

The backup records the previous DHCP/manual configuration, IP address, subnet mask, router and DNS configuration.

MacDPI OneClick also:

- checks for a potential `.240` LAN address conflict before enabling global mode;
- pins MacDPI to the reviewed upstream commit `30556c5dd90d23819e32b4c2bfb8b8b670cde8a4` instead of silently using whatever happens to be newest on `main`;
- builds ByeDPI/ciadpi and sing-box locally rather than shipping opaque third-party binaries;
- tests internet connectivity after installation and each enable operation;
- stops MacDPI and restores the saved network configuration automatically if the connectivity test fails;
- restores the saved network configuration when DPI is disabled or MacDPI OneClick is uninstalled.

These protections reduce risk, but no networking tool can guarantee compatibility with every router, VPN, corporate network, captive portal or ISP configuration.

## What changes on the Mac

While global mode is active, upstream MacDPI may:

- create/use a TUN networking path;
- temporarily configure a LAN address ending in `.240`;
- change DNS while the service is active;
- block QUIC/UDP 443 so supported traffic can fall back to TCP;
- install the system launch daemon `com.macdpi`;
- start automatically at boot.

Closing the Terminal window does **not** stop the service. Use option **3** to disable it and restore the saved network configuration.

## Dependencies and source transparency

The project does not operate a remote VPN server and does not intentionally collect telemetry in the wrapper scripts.

Runtime/build dependencies include:

- [MacDPI](https://github.com/monotter/MacDPI)
- [sing-box](https://github.com/SagerNet/sing-box)
- [ByeDPI](https://github.com/hufrea/byedpi)
- [Homebrew](https://brew.sh/)

Administrator privileges are required because TUN networking, network configuration and the system launch daemon need elevated access.

## If something goes wrong

Choose **3) Disable DPI Bypass** first. MacDPI OneClick will stop the service and restore the saved network configuration.

If you want to remove everything, choose **6) Uninstall MacDPI Completely**. The project folder is moved to the Trash after the network restoration attempt.

For security details and reporting, see [SECURITY.md](SECURITY.md).

## Turkish documentation

See [README_TR.md](README_TR.md).

## Credits

MacDPI OneClick is an unofficial convenience wrapper around MacDPI. Credit for MacDPI, sing-box and ByeDPI belongs to their respective maintainers and contributors.

## License

The wrapper scripts and documentation in this repository are licensed under the MIT License. Third-party projects retain their own licenses.
