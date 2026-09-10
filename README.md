# jstats - FreeBSD Jail Monitor
Jstats is a tiny resource monitor for jails, small tool that I wrote for FreeBSD systems - lists RAM, CPU and disk space usage of the jails running in the host system.

**Tested On:** FreeBSD 13.1, 14.3-RELEASE, 15.0-RELEASE with standard jails defined in the **/etc/jail.conf** file.

I like raw, homemade jails, digging around in config files. I don't use any jail management tool/package, being a minimal&analogue guy with a try-to-do-it-yourself spirit, I never tested jstats with jails created by jail management packages, such as; BastilleBSD, iocage, cbsd, et cetera.

But while it's all in the kernel, it shouldn't matter which jail manager you use; **jstats** should work.

**Usage and a sample run:**

Run as root on the jail host. Run `./jstats.sh --help` for usage information. Use `./jstats.sh --include-mounts` to include other filesystems mounted below each jail root in the disk scan.

```console
[root@ozgur:~]# chmod +x jstats.sh
[root@ozgur:~]# ./jstats.sh

#Alternatively you might wish to move it somewhere inside $PATH for easier access;

[root@ozgur:~]# chmod +x jstats.sh
[root@ozgur:~]# mv jstats.sh /usr/local/bin/jstats
[root@ozgur:~]# jstats

========================================
 jstats 0.2 by Özgür Konstantin Kazanççı
  https://ozgurkazancci.com
========================================

------------
Jails Found:
------------
nginxsrv 10.10.10.2
phpserver 10.10.10.3
sqlserver 10.10.10.4

------------------
Jails - RAM usage:
[KiB] - [MiB] - [GiB]
------------------
nginxsrv: 2.1%
42908 KiB - 41.9 MiB - 0.0 GiB

phpserver: 2.2%
45540 KiB - 44.5 MiB - 0.0 GiB

sqlserver: 5.6%
112416 KiB - 109.8 MiB - 0.1 GiB

Total RAM usage: 9.9%

------------------
Jails - CPU usage:
------------------
nginxsrv: 2.1%
phpserver: 3.3%
sqlserver: 7.5%

Total CPU usage: 12.9%

RAM is summed process RSS; shared memory may be counted more than once.
CPU is the ps decaying average; totals can exceed 100%.

-------------------------
Jails - Disk space usage:
This might take a while..
Scope: jail root filesystem only (other mounts excluded).
-------------------------
1.3G    /jails/nginxsrv
1.7G    /jails/phpserver
1.4G    /jails/sqlserver

[root@ozgur:~]# 
```

**Notes:**

- RAM usage is the sum of process RSS, measured against host physical memory. Shared pages can be counted more than once.
- CPU usage comes from the decaying averages reported by `ps`. A jail can exceed 100% when it uses multiple CPUs.
- Percentages and converted memory values use at most one decimal place. RAM percentages are calculated from total RSS before rounding.
- Disk usage covers only the jail root filesystem by default. `--include-mounts` also scans filesystems mounted below it; shared mounts can be counted more than once.
- Failed measurements display `N/A` and return a nonzero exit status. A running jail without processes reports zero RAM and CPU usage.
- No active jails returns exit status 1, as in the original version.

Run `sh tests/test-jstats.sh` for the regression tests. These tests use controlled command output and do not create real jails.

**Change Logs:**

**10/09/2026 - v0.2**:

- Switched to numeric jail IDs to support spaces and special characters in names.
- Fixed unsafe jail-name formatting.
- Fixed numeric parsing under non-English locales.
- Added N/A results and nonzero exit codes for failed measurements.
- Calculated jail rows and totals from one process snapshot.
- Calculated RAM percentages from total RSS before rounding.
- Limited percentages and converted memory values to one decimal place.
- Corrected memory units to KiB, MiB and GiB.
- Fixed zero usage output for running jails without processes.
- Clarified RSS, CPU averages and disk measurement scope.
- Added --include-mounts to scan mounted filesystems.
- Added --help and automatic cleanup of private temporary files.
- Added regression tests for measurement errors and edge cases.
- Verified v0.2 on FreeBSD 14.3-RELEASE and FreeBSD 15.0-RELEASE.
- Aligned banner borders with the full author name.

**04/08/2022 - v0.1**:

- This is the first release and may contain bugs.
- Please report them to me.
