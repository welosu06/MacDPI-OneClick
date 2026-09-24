# Changelog

## v1.4.0

### Safer handling of occupied .240 addresses

Some local networks already have a device using an address such as `192.168.1.240`. Earlier safety logic treated that as a hard installation failure.

v1.4.0 changes this behavior:

- the conflict is detected and clearly reported;
- the installer does not force the occupied address;
- upstream MacDPI is allowed to continue if it can operate without applying the static address;
- MacDPI OneClick performs a post-start connectivity test;
- if connectivity is unhealthy, the service is stopped and the saved network configuration is restored automatically.

This keeps the system from blindly forcing a conflicting LAN address while avoiding unnecessary installation failures on networks where MacDPI works correctly without it.

### Existing safety protections retained

- backup of DHCP/manual IP configuration, subnet mask, router and DNS;
- automatic rollback after failed activation;
- restore of saved network configuration when DPI is disabled;
- restore before uninstall;
- pinned MacDPI upstream commit;
- local builds of third-party components;
- macOS release ZIP executable-permission verification;
- bilingual beginner-oriented Control Center.

## v1.3.0

Introduced network backup, automatic rollback, connectivity testing, upstream commit pinning, SECURITY.md and recovery documentation.

## v1.2.0

Added the bilingual beginner-friendly terminal Control Center and Desktop shortcut.

## v1.1.0

Introduced the single-terminal menu.

## v1.0.0

Initial public release.
