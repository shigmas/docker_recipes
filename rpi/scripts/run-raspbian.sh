#!/bin/sh

cp /usr/bin/qemu-arm-static /mnt/root/usr/bin

chroot /mnt/root ./install-kodi.sh

exit
