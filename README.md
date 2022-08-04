# jstats
A small tool that I wrote for FreeBSD systems - lists RAM, CPU and disk space usage of your jails in the system.

A sample run: 

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
10.10.10.2 web1
10.10.10.3 phpserver
10.10.10.4 sqlserver

------------------
Jails - RAM usage:
------------------
web1: 1.8%
phpserver: 1.6%
sqlserver: 9.6%

Total RAM usage: 13.0%

------------------
Jails - CPU usage:
------------------
web1: 2.1%
phpserver: 3.3%
sqlserver: 7.5%

Total CPU usage: 12.9%

-------------------------
Jails - Disk space usage:
-------------------------
1.3G    /jails/web1
1.7G    /jails/phpserver
1.4G    /jails/sqlserver

[root@ozgur:~]# 
```
