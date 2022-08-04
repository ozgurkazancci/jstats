#!/bin/sh

printf "\n=============================="
printf "\n jstats 0.1 by Ozgur Kazancci"
printf "\n  https://ozgurkazancci.com"
printf "\n==============================\n"

printf "\n"

if [ "$(jls name | xargs)" = "" ]; then printf "No jail found?\n\n";

else

jails=`jls name | xargs | sed 's/ / -J /g'`
printf "\n------------"
printf "\nJails Found:"
printf "\n------------\n"

jls | awk '{ print $2,$3 }' | tail -n +2

printf "\n------------------"
printf "\nJails - RAM usage:"
printf "\n------------------\n"
jls name | while SUM= read -r line; do printf "$line: " && ps -o %mem= -J "$line" | awk '{sum+=$1} END {printf("%.1f%%\n",sum)}'; done
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
fi;
