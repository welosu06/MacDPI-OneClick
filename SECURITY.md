# Security

MacDPI OneClick changes system networking, so transparency and rollback are treated as first-class requirements.

## What the wrapper does

The wrapper scripts may request administrator privileges to:

- install/remove the `com.macdpi` launch daemon;
- change the active network service between DHCP/manual configuration;
- temporarily change DNS;
- operate the TUN-based routing path used by upstream MacDPI.

The wrapper does not intentionally collect telemetry, account credentials, browser data or user files.

## Network backup and rollback

Before the first network change, MacDPI OneClick stores the active network configuration in:

`~/.macdpi-oneclick/network-backup`

The backup contains the active network service, DHCP/manual mode, IP, subnet mask, router and DNS configuration.

The saved configuration is restored when:

- installation fails after network changes begin;
- post-install connectivity checks fail;
- DPI is disabled from the Control Center;
- MacDPI OneClick is uninstalled.

## Upstream pinning

MacDPI is pinned to:

`30556c5dd90d23819e32b4c2bfb8b8b670cde8a4`

This prevents a future change on the upstream `main` branch from being pulled silently by an existing release.

The pinned upstream commit is not GPG-signed on GitHub, so commit pinning improves reproducibility but is not equivalent to cryptographic publisher verification.

## Local builds

MacDPI OneClick does not bundle prebuilt copies of ByeDPI/ciadpi or sing-box. Upstream MacDPI's build process downloads its pinned sources and compiles them locally.

## Known networking considerations

Global mode may temporarily use a LAN address ending in `.240`. MacDPI OneClick performs a pre-check for an obvious address conflict before starting the service, but no LAN conflict detection method is perfect.

Compatibility can also vary with:

- corporate or managed networks;
- active VPN clients;
- captive portals;
- custom DNS or manually configured network interfaces;
- routers that use unusual subnets;
- ISP-specific network behavior.

## Recovery

If networking behaves unexpectedly:

1. Open **MacDPI OneClick.command** from the Desktop.
2. Choose **3) Disable DPI Bypass**.
3. Wait for the original network settings to be restored.
4. If you no longer want the software, choose **6) Uninstall MacDPI Completely**.

You can also restore network settings manually from macOS System Settings if necessary.

## Reporting a security issue

Do not post secrets, credentials or private network information in a public GitHub issue. For reproducible bugs, include the macOS version, Mac architecture, the exact MacDPI OneClick release, and sanitized error output.
