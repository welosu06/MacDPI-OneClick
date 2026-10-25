# Security

MacDPI OneClick changes system networking and installs/removes a system launch daemon. The v1.6.0 safety design therefore focuses on **recovery, reproducibility and transparency** rather than claiming that network modification is risk-free.

## Security objective

The primary operational objective is:

> If a MacDPI activation fails or produces an unhealthy connection, stop the service and make a best-effort restoration of the clean network configuration that existed immediately before activation.

This reduces the chance of leaving the Mac with an unexpected static IP or DNS configuration after a failed operation.

## Clean-network backups

Before a new activation, the wrapper records the active network service's DHCP/manual state, IP, subnet mask, router and DNS configuration. It also records interface context and, where available, Wi-Fi context.

Backups live under:

`~/.macdpi-oneclick/network-backups/`

The current recovery target is referenced by:

`~/.macdpi-oneclick/active-backup`

The backup set is bounded; old backups are pruned rather than growing forever.

### Legacy migration

v1.3/v1.4 stored a single backup at:

`~/.macdpi-oneclick/network-backup`

v1.5.0 imports that legacy backup before touching an already running service when possible, so upgrading users retain a recovery path.

## Rollback behavior

When activation or a post-start connectivity test fails, the wrapper attempts to:

1. stop/remove `com.macdpi`;
2. restore the active clean-network backup;
3. restore saved DNS behavior;
4. flush relevant DNS caches;
5. test normal internet connectivity again.

Rollback is a best-effort safety mechanism, not a formal transactional guarantee. macOS, a VPN client, MDM software or another network process can change settings concurrently.

## IP configuration and physical-interface binding

v1.6.0 keeps the current DHCP/manual IP configuration by default. The patched runtime only invokes the upstream static-IP helper if an operator explicitly sets `MACDPI_USE_STATIC_IP=1`; this is not enabled by the installer or launch daemon.

The locally compiled ByeDPI patch binds outbound sockets to the selected physical interface with macOS socket options. An invalid interface is an error. The launcher rejects a `utun` default interface to avoid silently recirculating bypass traffic through another tunnel. Switching networks may require disabling and re-enabling the service.

The default strategy uses IPv4 sockets. IPv6-only networks and VPN default routes need separate validation. TUN uses gVisor; DNS is redirected through HTTPS while active. All reachability checks keep TLS certificate validation enabled. A generic internet health result and the Discord updater health result are reported separately; the latter is not proof of voice/UDP connectivity.

## Emergency recovery

Control Center option **7 — Emergency Restore Network** is deliberately available separately from uninstall. It tries to stop the service and restore the active clean backup.

If no usable backup exists, the user can explicitly choose a last-resort DHCP + automatic-DNS reset for the currently active service. This fallback requires confirmation because it can be wrong for intentionally static/manual enterprise networks.

## Concurrent operation protection

Network-changing actions use a lock directory containing the running process ID. This reduces accidental concurrent install/enable/disable/recovery operations. A stale lock can be replaced when the recorded process no longer exists. Fatal installer errors release their own lock before waiting for Enter; release never removes another process's lock.

This is a local coordination mechanism, not protection against unrelated third-party software changing the network at the same time.

## VPN, Private Relay and captive portals

The wrapper can warn when `utun` interfaces exist because VPN software, Private Relay and system services may use them. A `utun` interface is not itself treated as evidence of a VPN or a fault.

The installer also performs a lightweight captive-portal check. These are advisory signals; the real decision after activation comes from connectivity health tests.

## Administrator password

The wrapper uses `sudo` for operations that require administrator privileges. The password prompt is handled by macOS. The wrapper does not intentionally read, persist or log the administrator password.

## Diagnostics privacy

The diagnostics helper masks IPv4/IPv6-like values and replaces the user's home-directory path before writing the report.

Redaction is best-effort. Users should review a diagnostics file before publishing it because logs produced by third-party components can contain unexpected content that no simple redaction rule can perfectly classify.

## Source and dependency transparency

The wrapper pins MacDPI to:

`30556c5dd90d23819e32b4c2bfb8b8b670cde8a4`

The v1.6.0 build patch pins ByeDPI to full commit `ba532298de7b28cfe854aea83d061369d13ca290` and keeps sing-box `v1.13.14`. `patches/` contains the runtime and socket-binding diffs; `ApplyFixes.sh` validates the upstream revision and patch applicability before applying them. The build applies the ByeDPI patch before compilation. Repair retains these patches in the installed launcher directory.

Third-party binaries are built locally rather than bundled in the MacDPI OneClick release ZIP. Pinning prevents the wrapper release from silently following future MacDPI `main` changes, but the pinned MacDPI commit is not GPG-verified on GitHub; pinning is reproducibility, not cryptographic publisher authentication.

## Telemetry and remote servers

The MacDPI OneClick wrapper scripts intentionally contain no telemetry collector and do not operate a remote VPN service. Installation naturally contacts upstream download/source hosts such as GitHub and Homebrew when dependencies are required.

## Gatekeeper

The release is currently not Apple Developer ID signed/notarized. macOS may require **Right-click → Open** or **System Settings → Privacy & Security → Open Anyway** for the first launch. Users should only approve a release they intentionally obtained from this repository.

## Uninstall

Uninstall first attempts network restoration, then removes the launch daemon and checks whether `com.macdpi` still appears loaded. Homebrew, Go and Apple Command Line Tools are not removed because they are shared system-development dependencies that other software may use.

## Known limitations

No network wrapper can guarantee safe behavior on every environment. Relevant variables include:

- corporate/MDM-managed networking;
- active VPN software;
- iCloud Private Relay and other system tunnels;
- manually configured static IP/DNS;
- captive portals;
- unusual subnets and routers;
- ISP behavior;
- future macOS networking changes;
- third-party software modifying the same network service concurrently.

## Reporting security issues

Do not include passwords, authentication tokens, private keys or unsanitized private network data in a public issue. When reporting a reproducible problem, useful non-secret context includes the Mac architecture, macOS version, MacDPI OneClick version and a reviewed/redacted diagnostics report.
