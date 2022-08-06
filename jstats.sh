#!/bin/sh

printf "\n=============================="
printf "\n jstats 0.1 by Ozgur Kazancci"
printf "\n  https://ozgurkazancci.com"
printf "\n==============================\n"

if [ "$(jls name | xargs)" = "" ]; then printf "\nNo jail found?\n\n"; exit 1;

else

jails=`jls name | xargs | sed 's/ / -J /g'`
printf "\n------------"
printf "\nJails Found:"
printf "\n------------\n"

jls name ip4.addr

printf "\n------------------"
printf "\nJails - RAM usage:"
printf "\n[kB] - [MB] - [GB]"
printf "\n------------------\n"
jls name | while SUM= read -r line; do printf "$line: " && ps -o %mem= -J "$line" | awk '{sum+=$1} END {printf("%.1f%%\n",sum)}' && \
ps -o rss -J "$line" | awk '{ total+=$1 } END { printf total " kB - " total/1000 " MB - "  total/1000**2 " GB\n\n" }'; done

printf "\nTotal RAM usage: "
ps -o %mem= -J $jails | awk '{sum+=$1} END {printf("%.1f%%\n",sum)}'

printf "\n------------------"
printf "\nJails - CPU usage:"
printf "\n------------------\n"
jls name | while SUM= read -r line; do printf "$line: " && ps -o %cpu= -J "$line" | awk '{sum+=$1} END {printf("%.1f%%\n",sum)}'; done

printf "\nTotal CPU usage: "
ps -o %cpu= -J $jails | awk '{sum+=$1} END {printf("%.1f%%\n",sum)}'

printf "\n-------------------------"
printf "\nJails - Disk space usage:"
printf "\n-------------------------\n"
jls path | while SUM= read -r line; do du -sh "$line"; done
printf "\n"
exit 0;
fi
