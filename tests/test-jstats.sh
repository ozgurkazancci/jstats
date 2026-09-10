#!/bin/sh
# Regression tests with controlled command output; real jail tests run separately.
set -u
BASE=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
WORK=$(mktemp -d "${TMPDIR:-/tmp}/jstats-tests.XXXXXXXX") || exit 1
trap 'rm -rf "$WORK"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
mkdir -p "$WORK/bin" "$WORK/tmp"
export TEST_WORK="$WORK"
cat > "$WORK/bin/mock" <<'MOCK'
#!/bin/sh
tool=${0##*/}
printf '%s' "$tool" >> "$TEST_WORK/commands"
for arg do printf ' <%s>' "$arg" >> "$TEST_WORK/commands"; done
printf '\n' >> "$TEST_WORK/commands"
case "$tool" in
uname) printf 'FreeBSD\n';;
id) printf '0\n';;
jls)
    [ "$CASE" != jls_error ] || { printf 'jls: injected failure\n' >&2; exit 1; }
    [ "$CASE" != no_jails ] || exit 0
    if [ "$1" = jid ]; then printf '11\n22\n'; exit 0; fi
    [ "$1" = -j ] || { printf 'unexpected jls request\n' >&2; exit 2; }
    jid=$2; field=$3
    case "$CASE/$jid" in metadata_error/22|gone/22) printf 'jls: jail disappeared\n' >&2; exit 1;; esac
    case "$field" in
      jid) printf '%s\n' "$jid";;
      name) if [ "$jid" = 11 ]; then printf '%s\n' "web test'%Z"; else printf 'db\n'; fi;;
      ip4.addr) printf '192.0.2.%s\n' "$jid";;
      path) printf '/fixture/jail %s\n' "$jid";;
      *) printf 'unexpected jls field\n' >&2; exit 2;;
    esac;;
ps)
    [ "${LC_ALL-}" = C ] || { printf 'numeric locale was not fixed\n' >&2; exit 2; }
    [ "$CASE" != ps_error ] || { printf 'ps: injected failure\n' >&2; exit 1; }
    case "$CASE" in
      bad_ps) printf 'this is not process data\n';;
      empty_ps) :;;
      empty_jails) printf '0 999999 99.9\n';;
      rounding)
        printf '0 999999 99.9\n'
        i=0
        while [ "$i" -lt 20 ]; do printf '11 400 0.0\n'; i=$((i+1)); done;;
      *) printf '0 999999 99.9\n11 32768 2.7\n11 16384 1.8\n22 8192 0.1\n';;
    esac;;
sysctl)
    [ "$CASE" != sysctl_error ] || { printf 'sysctl: injected failure\n' >&2; exit 1; }
    [ "$1" != -n ] || shift
    for field do
      case "$field" in
        hw.availpages) if [ "$CASE" = bad_memory ]; then printf '0\n'; else printf '262144\n'; fi;;
        hw.pagesize) printf '4096\n';;
        *) printf 'unexpected sysctl\n' >&2; exit 2;;
      esac
    done;;
du)
    [ "$CASE" != du_error ] || { printf 'du: injected permission failure\n' >&2; exit 1; }
    for arg do path=$arg; done
    printf '8.0K\t%s\n' "$path";;
esac
MOCK
for tool in uname id jls ps sysctl du; do
    cp "$WORK/bin/mock" "$WORK/bin/$tool"
    chmod +x "$WORK/bin/$tool"
done
export PATH="$WORK/bin:$PATH"
export TMPDIR="$WORK/tmp"
passed=0
failed=0
check() {
    label=$1; shift
    if "$@"; then
        passed=$((passed+1)); printf 'PASS %s\n' "$label"
    else
        failed=$((failed+1)); printf 'FAIL %s\n' "$label"
        cat "$WORK/out" "$WORK/err"
    fi
}
contains() { grep -F -- "$1" "$WORK/out" >/dev/null; }
absent() { ! grep -F -- "$1" "$WORK/out" >/dev/null; }
clean_tmp() { [ -z "$(find "$WORK/tmp" -mindepth 1 -print)" ]; }
run_case() {
    CASE=$1; shift; export CASE
    : > "$WORK/commands"
    sh "$BASE/jstats.sh" "$@" > "$WORK/out" 2> "$WORK/err"
    rc=$?
}
run_case normal
check 'normal exit' test "$rc" -eq 0
check 'version 0.2' contains 'jstats 0.2'
check 'literal special name' contains "web test'%Z: 4.7%"
check 'raw RSS memory total excludes host' contains 'Total RAM usage: 5.5%'
check 'CPU total from the same snapshot' contains 'Total CPU usage: 4.6%'
check 'binary memory units and short decimals' contains '49152 KiB - 48.0 MiB - 0.0 GiB'
check 'one process snapshot' test "$(grep -c '^ps ' "$WORK/commands")" -eq 1
check 'no per-name ps selector' test "$(grep -c '^ps .*<-J>' "$WORK/commands")" -eq 0
check 'one numeric jail discovery' test "$(grep -c '^jls <jid>$' "$WORK/commands")" -eq 1
check 'default disk scan stays on its filesystem' grep -E '^du .*<(-x|-shx|-sx)>' "$WORK/commands"
check 'temporary files removed after success' clean_tmp
run_case rounding
check 'round RSS only after summing' contains 'Total RAM usage: 0.8%'
run_case empty_jails
check 'empty persistent jail is successful' test "$rc" -eq 0
check 'empty persistent jail has numeric zero' contains '0 KiB - 0.0 MiB - 0.0 GiB'
check 'empty persistent jail has zero percent' contains 'Total RAM usage: 0.0%'
run_case normal --include-mounts
check 'include-mounts succeeds' test "$rc" -eq 0
check 'include-mounts omits -x' test "$(grep -Ec '^du .*<(-x|-shx|-sx)>' "$WORK/commands")" -eq 0
for fault in ps_error bad_ps empty_ps sysctl_error bad_memory metadata_error gone du_error; do
    run_case "$fault"
    check "$fault returns nonzero" test "$rc" -ne 0
    check "$fault reports unavailable data" contains 'N/A'
    check "$fault reports a diagnostic" test -s "$WORK/err"
    check "$fault cleans temporary files" clean_tmp
done
run_case jls_error
check 'jls discovery failure returns nonzero' test "$rc" -ne 0
check 'jls discovery failure has diagnostic' test -s "$WORK/err"
check 'jls discovery failure cleans temporary files' clean_tmp
run_case no_jails
check 'no jails preserves exit 1' test "$rc" -eq 1
check 'no jails performs no process collection' test "$(grep -c '^ps ' "$WORK/commands")" -eq 0
check 'no jails cleans temporary files' clean_tmp
run_case normal --help
check 'help succeeds' test "$rc" -eq 0
check 'help documents mount option' contains '--include-mounts'
check 'help performs no data collection' test ! -s "$WORK/commands"
run_case normal --invalid-option
check 'unknown option returns nonzero' test "$rc" -ne 0
check 'unknown option performs no data collection' test ! -s "$WORK/commands"
printf '\n%d passed; %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
