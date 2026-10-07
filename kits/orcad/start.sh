#!/bin/sh
set -eu
umask 077
export ORCA_USER_DATA="$HOME/.orca"
mkdir -p "$ORCA_USER_DATA"

# A daemon restart may rerun startup while the previous hook is still alive.
exec 9>"$ORCA_USER_DATA/kit-service.lock"
flock -n 9 || exit 0

child=
stop() {
    trap - TERM INT
    if [ -n "$child" ]; then
        kill "$child" 2>/dev/null || true
        wait "$child" 2>/dev/null || true
    fi
    exit 0
}
trap stop TERM INT

while :; do
    orcad --json --bind 127.0.0.1 --port 6800 \
        >"$ORCA_USER_DATA/kit-ready.jsonl" 2>>"$ORCA_USER_DATA/kit-service.log" &
    child=$!
    wait "$child" || true
    child=
    sleep 5
done
