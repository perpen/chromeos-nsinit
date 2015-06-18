#!/bin/bash
set -e
base=$(readlink -f $(dirname $0))
config=$(mktemp /tmp/crouton-container.XXX.json)
rootfs="/mnt/stateful_partition/crouton/chroots/$1"
name="$(basename $rootfs)"
hostname=$name

[ -d $rootfs/etc ] || {
	echo "$0: not a valid rootfs: $rootfs" 1>&2
	exit 1
}

if [ "$1" = "--with-console" ]; then
	shift
	console="$(tty)"
	console_section='{ "source": "'$console'", "destination": "/dev/console", "device": "bind", "flags": 20480, "data": "", "relabel": "", "premount_cmds": null, "postmount_cmds": null },'
	echo $console_section
else
	console_section=""
fi

cat $base/config.json.template | \
	sed "s#CROUTON_CONTAINER_ROOTFS#$rootfs#g
	     s#CROUTON_CONTAINER_HOSTNAME#$hostname#g
	     s#CROUTON_CONTAINER_CONSOLE_SECTION#$console_section#g" > $config

##FIXME
sudo rm -rf  /var/run/nsinit/
sudo /henri/nsinit exec \
	--env container=nsinit \
	--config $config \
	/usr/lib/systemd/systemd --system
