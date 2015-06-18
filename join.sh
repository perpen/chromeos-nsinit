#!/bin/bash
set -e
cd /var/run/nsinit/nsinit
$(readlink -f $(dirname $0))/nsinit exec /usr/bin/bash
