#!/usr/bin/env bash
## henri - From https://github.com/docker/docker/blob/master/contrib/mkimage-arch.sh
## Only modified to use the variables below.
image_name=archlinux
tz=Europe/London
locale='en_GB.UTF-8 UTF-8'
repo='http://www.mirrorservice.org/sites/ftp.archlinux.org/$repo/os/$arch'

# Generate a minimal filesystem for archlinux and load it into the local
# docker as "archlinux"
# requires root
set -e

hash pacstrap &>/dev/null || {
	echo "Could not find pacstrap. Run pacman -S arch-install-scripts"
	exit 1
}

hash expect &>/dev/null || {
	echo "Could not find expect. Run pacman -S expect"
	exit 1
}

export LANG="C.UTF-8"

ROOTFS=/var/tmp/minijail-archlinux-$$
mkdir $ROOTFS
chmod 755 $ROOTFS

# packages to ignore for space savings
PKGIGNORE=(
    cryptsetup
    device-mapper
    dhcpcd
    jfsutils
    linux
    lvm2
    man-db
    man-pages
    mdadm
    nano
    pciutils
    pcmciautils
    reiserfsprogs
    s-nail
    usbutils
    xfsprogs
)
IFS=','
PKGIGNORE="${PKGIGNORE[*]}"
unset IFS

expect <<EOF
	set send_slow {1 .1}
	proc send {ignore arg} {
		sleep .1
		exp_send -s -- \$arg
	}
	set timeout 60

	spawn pacstrap -C ./mkimage-arch-pacman.conf -c -d -G -i $ROOTFS base haveged --ignore $PKGIGNORE
	expect {
		-exact "anyway? \[Y/n\] " { send -- "n\r"; exp_continue }
		-exact "(default=all): " { send -- "\r"; exp_continue }
		-exact "installation? \[Y/n\]" { send -- "y\r"; exp_continue }
	}
EOF

arch-chroot $ROOTFS /bin/sh -c 'rm -r /usr/share/man/*'
arch-chroot $ROOTFS /bin/sh -c "haveged -w 1024; pacman-key --init; pkill haveged; pacman -Rs --noconfirm haveged; pacman-key --populate archlinux; pkill gpg-agent"
arch-chroot $ROOTFS /bin/sh -c "ln -s /usr/share/zoneinfo/$tz /etc/localtime"
arch-chroot $ROOTFS /bin/sh -c "pacman -S --noconfirm systemd vim strace"
echo $locale > $ROOTFS/etc/locale.gen
arch-chroot $ROOTFS locale-gen
#arch-chroot $ROOTFS /bin/sh -c 'echo "Server = https://mirrors.kernel.org/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist'
arch-chroot $ROOTFS /bin/sh -c "echo 'Server = $repo' > /etc/pacman.d/mirrorlist"

# udev doesn't work in containers, rebuild /dev
DEV=$ROOTFS/dev
rm -rf $DEV
mkdir -p $DEV
mknod -m 666 $DEV/null c 1 3
mknod -m 666 $DEV/zero c 1 5
mknod -m 666 $DEV/random c 1 8
mknod -m 666 $DEV/urandom c 1 9
mkdir -m 755 $DEV/pts
mkdir -m 1777 $DEV/shm
mknod -m 666 $DEV/tty c 5 0
mknod -m 600 $DEV/console c 5 1
mknod -m 666 $DEV/tty0 c 4 0
mknod -m 666 $DEV/full c 1 7
mknod -m 600 $DEV/initctl p
mknod -m 666 $DEV/ptmx c 5 2
ln -sf /proc/self/fd $DEV/fd

#tar --numeric-owner --xattrs --acls -C $ROOTFS -c . | docker import - $image_name
#docker run --rm -t $image_name echo Success.
#rm -rf $ROOTFS

echo $ROOTFS
