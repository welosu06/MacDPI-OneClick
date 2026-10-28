# MacDPI OneClick v1.6.1

**Mac only.** [Türkçe: çok kolay kurulum](README_TR.md)

1. Download [MacDPI-OneClick-v1.6.1.zip](https://github.com/welosu06/MacDPI-OneClick/releases/download/v1.6.1/MacDPI-OneClick-v1.6.1.zip), not the GitHub source-code archive.
2. Extract it and open `MacDPI.command` in the extracted folder.
3. Type **1**, then press **Enter**. Use option 1 for upgrades too.
4. Enter your Mac login password if requested; Terminal does not show characters while typing.
5. Wait for successful installation, then quit and reopen Discord.

After installation, use the desktop launcher: **2** enables DPI, **3** disables it,
**4** checks connectivity, **7** restores the network if needed.

This release waits for a stable physical IPv4 network before starting the proxy/TUN,
supervises both workers, and restarts after sustained network changes or worker exits.
It preserves the v1.6.0 Discord TLS fixes and the default of keeping the existing IP.
The affected user's Mac reportedly works after the repair. Automated tests cover
patch application, network readiness and worker supervision, not all real boot/network conditions.

See [Türkçe instructions and technical details](README_TR.md), [security and recovery](SECURITY.md),
and [change history](CHANGELOG.md). Third-party components are built locally from pinned sources.
