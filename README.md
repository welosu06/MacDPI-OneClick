# MacDPI OneClick

**One click. System-wide. No per-app proxy setup.**

MacDPI OneClick is a macOS installer and launcher wrapper for [MacDPI](https://github.com/monotter/MacDPI). It turns MacDPI into a simple global setup for browsers and desktop apps while keeping the underlying components transparent and locally built.

> **Supported:** Apple Silicon (M1–M5 / arm64) and Intel Macs.

## Why this exists

Browser-only proxy tools can work in one app and fail in another. MacDPI OneClick uses MacDPI's global TUN mode so Chrome, Safari, Edge, Discord and other applications can use the same system-wide DPI bypass path.

## Quick start

1. Open the [latest release](https://github.com/welosu06/MacDPI-OneClick/releases/latest).
2. Download **MacDPI-OneClick-v1.0.0.zip** from **Assets**.
3. Extract the ZIP.
4. Double-click **Install.command**.
5. If macOS blocks the first launch, right-click **Install.command** → **Open** → **Open**.
6. Enter your macOS administrator password when requested and wait for setup to finish.

> Use the ZIP from **Releases / Assets**, not the repository's **Code → Download ZIP** archive. The release package is built on macOS and preserves executable permissions for the launchers.

After setup, the installer copies four launchers to your Desktop:

| File | Action |
| --- | --- |
| `DPI_Ac.command` | Enable/restart global DPI bypass |
| `DPI_Kapat.command` | Stop the service and restore normal networking |
| `Durum.command` | Show service status and recent logs |
| `Kaldir.command` | Remove MacDPI OneClick |

## What the installer does

- Detects Apple Silicon (`arm64`) or Intel (`x86_64`).
- Installs/uses Xcode Command Line Tools when required.
- Installs Homebrew when the user approves it and Homebrew is missing.
- Uses `go@1.25` for compatibility with the sing-box version currently pinned by upstream MacDPI.
- Downloads MacDPI from its official repository.
- Builds `ciadpi` and `sing-box` locally on the user's Mac.
- Configures `MODE=global`, `BLOCK_QUIC=true`, and `MAX_CONN=8192`.
- Installs MacDPI as a `launchd` service with automatic startup.

## Architecture

```text
Apps / Browsers
      │
      ▼
macOS TUN
      │
      ▼
sing-box
      │
      ▼
ciadpi / ByeDPI
      │
      ▼
Internet
```

This repository does not operate a remote VPN server. The local MacDPI stack handles TUN routing and DPI desynchronization on-device.

## Security & transparency

This repository intentionally does **not ship third-party binaries**. During installation it downloads the official MacDPI source and lets upstream MacDPI build its pinned components locally.

Dependencies:
- [MacDPI](https://github.com/monotter/MacDPI)
- [sing-box](https://github.com/SagerNet/sing-box)
- [ByeDPI](https://github.com/hufrea/byedpi)
- [Homebrew](https://brew.sh/)

Administrator privileges are required because TUN networking, network configuration and the system `launchd` service need elevated access.

## Network note

Upstream MacDPI currently uses a temporary static host address ending in `.240` while active. If another device on the local network already uses that address, an IP conflict can occur.

Network and ISP behavior varies, so operation cannot be guaranteed on every connection.

## Turkish documentation

See [README_TR.md](README_TR.md).

## Credits

MacDPI OneClick is a convenience wrapper around the upstream MacDPI project. Credit for MacDPI, sing-box and ByeDPI belongs to their respective maintainers and contributors.

## License

The wrapper scripts and documentation in this repository are licensed under the MIT License. Third-party projects downloaded at runtime retain their own licenses.
