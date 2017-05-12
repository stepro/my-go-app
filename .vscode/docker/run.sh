#!/bin/sh
"$(dirname $0)/watch.sh" &
exec "$@"
