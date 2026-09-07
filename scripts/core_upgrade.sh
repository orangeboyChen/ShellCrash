#!/bin/sh

CRASHDIR=${CRASHDIR:-$(CDPATH= cd -- "$(dirname "$0")" && pwd)}
task_script="$CRASHDIR/task/task.sh"
channel=${2:-auto}

[ "$1" = update_core ] || exit 2
case "$channel" in
    auto|release|alpha) ;;
    *) exit 2 ;;
esac
[ -x "$task_script" ] || exit 1
. "$CRASHDIR/configs/command.env" 2>/dev/null
[ -n "$BINDIR" ] && [ -w "$BINDIR" ] || exit 1

if [ "$(id -u 2>/dev/null)" = 0 ] && command -v systemd-run >/dev/null 2>&1 &&
    grep -q systemd /proc/1/comm 2>/dev/null; then
    systemd-run --unit="shellcrash-core-upgrade-$$" --collect --no-block --quiet \
        "$task_script" update_core "$channel" >/dev/null 2>&1
    exit $?
fi

if command -v setsid >/dev/null 2>&1; then
    setsid "$task_script" update_core "$channel" >/dev/null 2>&1 </dev/null &
else
    nohup "$task_script" update_core "$channel" >/dev/null 2>&1 </dev/null &
fi
exit 0
