# jstats
Jstats is a tiny resource monitor for jails, small tool that I wrote for FreeBSD systems - lists RAM, CPU and disk space usage of the jails running in the host system.

**Tested On:** FreeBSD 13.1 with standard jails defined within **/etc/jail.conf** file.

I like raw, homemade jails, digging around in config files. I don't use any jail management tool/package, being a minimal&analogue guy with a try-to-do-it-yourself spirit, I never tested jstats with jails created by jail management packages, such as; BastilleBSD, iocage, cbsd, et cetera.

But while it's all in the kernel, it shouldn't matter which jail manager you use; **jstats** should work.

**Usage and a sample run:**

```console
[root@ozgur:~]# chmod +x jstats.sh
[root@ozgur:~]# ./jstats.sh

#**Alternatively you might wish to move it somewhere inside $PATH for easier access;**

[root@ozgur:~]# chmod +x jstats.sh
[root@ozgur:~]# mv jstats.sh /usr/local/bin/jstats
[root@ozgur:~]# jstats

==============================
 jstats 0.1 by Ozgur Kazancci
  https://ozgurkazancci.com
==============================

------------
Jails Found:
------------
nginxsrv 10.10.10.2
phpserver 10.10.10.3
sqlserver 10.10.10.4

------------------
Jails - RAM usage:
[kB] - [MB] - [GB]
------------------
nginxsrv: 2.1%
42908 kB - 42.908 MB - 0.042908 GB

phpserver: 2.2%
45540 kB - 45.54 MB - 0.04554 GB

sqlserver: 5.6%
112416 kB - 112.416 MB - 0.112416 GB

Total RAM usage: 9.9%

------------------
Jails - CPU usage:
------------------
nginxsrv: 2.1%
phpserver: 3.3%
sqlserver: 7.5%

Total CPU usage: 12.9%

-------------------------
Jails - Disk space usage:
-------------------------
1.3G    /jails/nginxsrv
1.7G    /jails/phpserver
1.4G    /jails/sqlserver

[root@ozgur:~]# 
```
