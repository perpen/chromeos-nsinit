#!/bin/bash
set -e
[ $# = 1 ]
cd /var/run/nsinit/$1
$(readlink -f $(dirname $0))/nsinit exec /usr/bin/bash
