# jstats
A small tool that I wrote for FreeBSD systems - lists RAM, CPU and disk space usage of the jails running in the host system.

**Tested On:** FreeBSD 13.1 with standard jails. 

Never tested with jails created by those jail management packages, such as; bastille, iocage, cbsd, et cetera.

I like raw, homemade jails. I don't use any extra/additional jail management tool/package, being a minimal&analogue guy with a try-to-do-it-yourself spirit, I usually start building my jails with a completely naked jail.conf file located in /etc folder.

**A sample run:**

```console
[root@ozgur:~]# chmod +x jstats.sh
[root@ozgur:~]# ./jstats.sh

==============================
 jstats 0.1 by Ozgur Kazancci
  https://ozgurkazancci.com
==============================

------------
Jails Found:
------------
10.10.10.2 nginxsrv
10.10.10.3 phpserver
10.10.10.4 sqlserver

------------------
Jails - RAM usage:
------------------
nginxsrv: 1.8%
phpserver: 1.6%
sqlserver: 9.6%

Total RAM usage: 13.0%

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
