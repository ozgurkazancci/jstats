#!/bin/sh

VERSION=0.2
LC_ALL=C
export LC_ALL

usage() {
    cat <<EOF
Usage: jstats.sh [--include-mounts] [--help]

Report FreeBSD jail RAM, CPU and disk usage. Run as root.
  --include-mounts  Include mounted filesystems in disk usage.
                    Shared mounts may be counted again for each jail.
  --help            Show this help.

By default, disk usage covers only the jail root filesystem (du -x).
RAM is summed process RSS; shared memory may be counted more than once.
CPU is the ps decaying average; totals can exceed 100%.
Percentages and memory sizes use at most one decimal place.
EOF
}

include_mounts=0
for argument do
    case $argument in
        --include-mounts) include_mounts=1 ;;
        --help) usage; exit 0 ;;
        *) printf 'jstats: unknown option: %s\n' "$argument" >&2
           usage >&2
           exit 2 ;;
    esac
done

printf '\n=============================='
printf '\n jstats %s by Ozgur Kazancci' "$VERSION"
printf '\n  https://ozgurkazancci.com'
printf '\n==============================\n'

for required_command in awk cat du id jls mktemp ps rm sysctl uname; do
    if ! command -v "$required_command" >/dev/null 2>&1; then
        printf 'jstats: required command not found: %s\n' "$required_command" >&2
        exit 1
    fi
done

if ! operating_system=$(uname -s); then
    printf 'jstats: cannot identify the operating system.\n' >&2
    exit 1
fi
if [ "$operating_system" != FreeBSD ]; then
    printf 'jstats: FreeBSD is required.\n' >&2
    exit 1
fi
if ! user_id=$(id -u); then
    printf 'jstats: cannot determine the current user.\n' >&2
    exit 1
fi
if [ "$user_id" != 0 ]; then
    printf 'jstats: run as root to collect complete jail statistics.\n' >&2
    exit 1
fi

umask 077
if ! work_dir=$(mktemp -d "${TMPDIR:-/tmp}/jstats.XXXXXXXXXX"); then
    printf 'jstats: cannot create a private temporary directory.\n' >&2
    exit 1
fi
trap 'rm -rf -- "$work_dir"' 0
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

status=0
warn() {
    printf 'jstats: %s\n' "$*" >&2
    status=1
}

if ! jls jid >"$work_dir/jids.raw"; then
    warn 'cannot list jails.'
    exit 1
fi
if ! awk '
    NF == 0 { next }
    NF != 1 || $1 !~ /^[0-9]+$/ || $1 == 0 { bad = 1; next }
    !seen[$1]++ { print $1 }
    END { if (bad) exit 1 }
' "$work_dir/jids.raw" >"$work_dir/jids"; then
    warn 'invalid jail ID data from jls.'
    exit 1
fi
if [ ! -s "$work_dir/jids" ]; then
    printf '\nNo jail found?\n\n'
    exit 1
fi

processes_ok=0
if ps -ax -o jid= -o rss= -o pcpu= >"$work_dir/processes"; then
    if JSTATS_WORK_DIR="$work_dir" awk '
        BEGIN { directory = ENVIRON["JSTATS_WORK_DIR"] }
        FNR == NR { selected[$1] = 1; next }
        NF == 0 { next }
        NF != 3 || $1 !~ /^[0-9]+$/ || $2 !~ /^[0-9]+$/ ||
            $3 !~ /^[0-9]+([.][0-9]+)?$/ { bad = 1; next }
        { process_rows++ }
        $1 in selected { rss[$1] += $2; cpu[$1] += $3 }
        END {
            if (bad || !process_rows) exit 1
            for (jid in selected) {
                file = directory "/usage." jid
                printf "%.0f %.17g\n", rss[jid] + 0, cpu[jid] + 0 > file
                close(file)
                total_rss += rss[jid]
                total_cpu += cpu[jid]
            }
            printf "%.0f %.17g\n", total_rss + 0, total_cpu + 0 > (directory "/totals")
        }
    ' "$work_dir/jids" "$work_dir/processes"; then
        processes_ok=1
    else
        warn 'cannot process the process snapshot.'
    fi
else
    warn 'cannot collect the process snapshot.'
fi

memory_ok=0
if sysctl -n hw.availpages hw.pagesize >"$work_dir/memory.raw"; then
    if awk '
        NF != 1 || $1 !~ /^[0-9]+$/ || $1 <= 0 { bad = 1 }
        NR == 1 { pages = $1 }
        NR == 2 { page_size = $1 }
        END {
            if (bad || NR != 2) exit 1
            printf "%.0f\n", pages * page_size
        }
    ' "$work_dir/memory.raw" >"$work_dir/memory" &&
        IFS= read -r memory_bytes <"$work_dir/memory"; then
        memory_ok=1
    else
        warn 'invalid host memory data from sysctl.'
    fi
else
    warn 'cannot collect host memory capacity.'
fi

metadata_ok=1
while IFS= read -r jid; do
    jail_ok=1
    if ! jls -j "$jid" name >"$work_dir/name.$jid" ||
        ! IFS= read -r jail_name <"$work_dir/name.$jid" ||
        [ -z "$jail_name" ]; then
        warn "cannot read the name of jail JID $jid."
        printf 'JID %s\n' "$jid" >"$work_dir/name.$jid"
        jail_ok=0
    fi
    if ! jls -j "$jid" ip4.addr >"$work_dir/ip.$jid"; then
        warn "cannot read the IPv4 address of jail JID $jid."
        printf 'N/A\n' >"$work_dir/ip.$jid"
        jail_ok=0
    fi
    if ! jls -j "$jid" path >"$work_dir/path.$jid" ||
        ! IFS= read -r jail_path <"$work_dir/path.$jid"; then
        warn "cannot read the path of jail JID $jid."
        jail_ok=0
    else
        case $jail_path in
            /*) ;;
            *) warn "invalid root path for jail JID $jid."; jail_ok=0 ;;
        esac
    fi
    if [ "$jail_ok" -eq 0 ]; then
        : >"$work_dir/invalid.$jid"
        metadata_ok=0
    fi
done <"$work_dir/jids"

printf '\n------------\nJails Found:\n------------\n'
while IFS= read -r jid; do
    IFS= read -r jail_name <"$work_dir/name.$jid"
    jail_ip=
    IFS= read -r jail_ip <"$work_dir/ip.$jid"
    printf '%s %s\n' "$jail_name" "$jail_ip"
done <"$work_dir/jids"

print_ram() {
    if [ "$memory_ok" -eq 1 ]; then
        awk -v rss="$1" -v bytes="$memory_bytes" \
            'BEGIN { printf "%.1f%%\n", rss * 1024 / bytes * 100 }'
    else
        printf 'N/A\n'
    fi
}

printf '\n------------------\nJails - RAM usage:\n[KiB] - [MiB] - [GiB]\n------------------\n'
while IFS= read -r jid; do
    IFS= read -r jail_name <"$work_dir/name.$jid"
    printf '%s: ' "$jail_name"
    if [ "$processes_ok" -eq 1 ] && [ ! -f "$work_dir/invalid.$jid" ]; then
        IFS=' ' read -r rss cpu <"$work_dir/usage.$jid"
        print_ram "$rss"
        awk -v rss="$rss" 'BEGIN {
            printf "%.0f KiB - %.1f MiB - %.1f GiB\n\n", rss, rss / 1024, rss / 1048576
        }'
    else
        printf 'N/A\nN/A KiB - N/A MiB - N/A GiB\n\n'
    fi
done <"$work_dir/jids"

printf 'Total RAM usage: '
if [ "$processes_ok" -eq 1 ] && [ "$metadata_ok" -eq 1 ]; then
    IFS=' ' read -r total_rss total_cpu <"$work_dir/totals"
    print_ram "$total_rss"
else
    printf 'N/A\n'
fi

printf '\n------------------\nJails - CPU usage:\n------------------\n'
while IFS= read -r jid; do
    IFS= read -r jail_name <"$work_dir/name.$jid"
    printf '%s: ' "$jail_name"
    if [ "$processes_ok" -eq 1 ] && [ ! -f "$work_dir/invalid.$jid" ]; then
        IFS=' ' read -r rss cpu <"$work_dir/usage.$jid"
        awk -v cpu="$cpu" 'BEGIN { printf "%.1f%%\n", cpu }'
    else
        printf 'N/A\n'
    fi
done <"$work_dir/jids"

printf '\nTotal CPU usage: '
if [ "$processes_ok" -eq 1 ] && [ "$metadata_ok" -eq 1 ]; then
    awk -v cpu="$total_cpu" 'BEGIN { printf "%.1f%%\n", cpu }'
else
    printf 'N/A\n'
fi

printf '\nRAM is summed process RSS; shared memory may be counted more than once.\n'
printf 'CPU is the ps decaying average; totals can exceed 100%%.\n'
printf '\n-------------------------\nJails - Disk space usage:\nThis might take a while..\n'
if [ "$include_mounts" -eq 1 ]; then
    printf 'Scope: includes mounted filesystems (shared mounts may be counted again).\n'
else
    printf 'Scope: jail root filesystem only (other mounts excluded).\n'
fi
printf '%s\n' '-------------------------'
while IFS= read -r jid; do
    IFS= read -r jail_name <"$work_dir/name.$jid"
    if [ -f "$work_dir/invalid.$jid" ]; then
        printf '%s: N/A\n' "$jail_name"
        continue
    fi
    IFS= read -r jail_path <"$work_dir/path.$jid"
    if [ "$include_mounts" -eq 1 ]; then
        du -sh "$jail_path" >"$work_dir/disk.$jid"
    else
        du -sh -x "$jail_path" >"$work_dir/disk.$jid"
    fi
    if [ "$?" -eq 0 ]; then
        cat "$work_dir/disk.$jid"
    else
        warn "cannot measure disk usage for jail JID $jid."
        printf '%s: N/A\n' "$jail_name"
    fi
done <"$work_dir/jids"

printf '\n'
exit "$status"
