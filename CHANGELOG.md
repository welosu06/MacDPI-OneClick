## 1.6.1 — 2026-10-29

- Wait for a stable physical interface and IPv4 address before starting DPI/TUN.
- Stop and let launchd restart if either worker exits, rather than waiting forever on helper jobs.
- Restart on sustained interface/address changes; ensure termination exits after cleanup.
- Include the boot repair in fresh installs and repairs; add regression tests.
- Add short Turkish install/upgrade instructions with direct ZIP links.

# Changelog

## v1.6.0 — 2026-10-25

- Fix the reproduced Discord desktop update failure using gVisor, physical-interface-bound ByeDPI sockets and `--split 2`.
- Ship auditable source patches, applied on every installation/repair; pin the full ByeDPI revision.
- Keep the current IP configuration by default instead of selecting `.240`.
- Add a separate SecureTransport-based Discord updater health check without disabling certificate verification.
- Prefer the extracted release's own installer when upgrading an existing installation.
- Release an installer's own lock before waiting on a fatal error; never delete another operation's lock.
- Add clean-source patch/build, socket-binding, upgrade-selection, idempotence and lock-ownership regression checks.
- Generalize the release workflow to package VERSION, include patches, verify ZIP permissions, and publish when VERSION changes on main.

## v1.5.0

v1.5.0 is the largest safety/recovery update so far. It changes the wrapper from a simple installer/menu into a more defensive network-control layer around MacDPI.

### New: per-activation clean network backups

- Creates a new clean network backup before a fresh activation.
- Records DHCP/manual mode, IP, subnet mask, router and DNS.
- Records network/interface context where available.
- Tracks the active recovery backup separately.
- Prunes old backups so history does not grow without bound.

### New: v1.3/v1.4 backup migration

- Detects the earlier `~/.macdpi-oneclick/network-backup` format.
- Imports the legacy backup into the new backup system before touching an already active service when possible.

### Improved: `.240` address safety

- Detects a responding `.240` candidate and warns the user.
- Does not intentionally force an address that appears occupied.
- Allows upstream MacDPI to continue if it can operate without applying the static address.
- Uses a post-start connectivity health check to decide whether the activation can remain active.
- Rolls back if health checks fail.

### New: rollback verification

After restoration, the wrapper now tests whether normal internet connectivity returned instead of assuming that a settings write automatically means the network is healthy.

### New: Emergency Restore Network

Control Center option **7** provides a recovery-first path without requiring uninstall.

- stops/removes the MacDPI service;
- restores the last clean backup;
- refreshes DNS state;
- verifies connectivity;
- can offer a user-confirmed DHCP/automatic-DNS fallback only when no backup exists.

### New: VPN/tunnel and captive-portal warnings

- Warns when `utun` interfaces are present without incorrectly declaring that they are always a VPN problem.
- Adds captive-portal awareness for networks that require a web sign-in.

### New: operation locking

Install, enable, disable, recovery and uninstall use a simple process lock to reduce accidental simultaneous network-changing operations.

### Fixed: Repair self-copy failure

Repair no longer tries to copy installed launcher scripts directly onto the same source paths when run from the installed launcher directory.

### New: Health Check

The status screen now reports:

- installation state;
- service state;
- internet health;
- active network interface/service;
- key safe MacDPI configuration values;
- last clean backup time;
- redacted recent service log lines.

### New: Redacted Diagnostics

Control Center option **8** creates a Desktop diagnostics file with best-effort masking of IP-like values and the user home path.

### Improved: uninstall cleanup

- restores the saved network state first;
- removes the launch daemon;
- checks whether `com.macdpi` still appears registered;
- leaves shared build tools such as Homebrew/Go/Command Line Tools installed.

### Improved: beginner onboarding and Gatekeeper instructions

Quick Start now explicitly covers both macOS approval paths:

- `Right-click → Open`;
- `System Settings → Privacy & Security → Open Anyway`.

### Transparency

- Wrapper version is visible in the Control Center.
- MacDPI remains pinned to commit `30556c5dd90d23819e32b4c2bfb8b8b670cde8a4`.
- The pinned MacDPI build currently uses ByeDPI ref `ba53229` and sing-box `v1.13.14`.
- Wrapper documentation explicitly states that the administrator password is not stored and that the project does not operate a remote VPN server.

## v1.4.0

Improved handling of occupied `.240` addresses: warn and continue cautiously instead of treating the condition as an unconditional installation failure; rely on connectivity testing and rollback.

## v1.3.0

Added network backup, automatic rollback, connectivity testing, upstream commit pinning and dedicated security/recovery documentation.

## v1.2.0

Added the bilingual beginner-friendly Control Center and Desktop shortcut.

## v1.1.0

Introduced the single-terminal menu.

## v1.0.0

Initial public release.
