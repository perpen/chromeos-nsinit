# chromeos-nsinit

Warning: As I was committing these files to github I made a few changes for clarity, and removed stuff that are specific to my setup (e.g. docker). So this will probably not work completely out of the box, but will provide you with a reasonable starting point.

- Create your container rootfs. If like me you favour Arch Linux you can use the provided `mkimage-arch.sh`, for other distros you may find something useful in https://github.com/docker/docker/blob/master/contrib/. It will probably be easier for you to create the initial rootfs from a traditional crouton chroot, or another machine.
- Copy the root fs to `/mnt/stateful_partition/crouton/chroots/<name>`. `<name>` is just an ID used to identify the environment from other scripts.
- From Chrome OS, run: `sudo ./crouton-container.sh --with-console <name>` to start the container and get a login prompt. You can then login as root and for example setup sshd. Once sshd is setup you will be able to run the script without `--with-console`, e.g. from your `/etc/init/crouton.conf`.
