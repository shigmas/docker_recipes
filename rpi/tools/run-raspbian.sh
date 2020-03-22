#!/bin/sh

cp /usr/bin/qemu-arm-static /mnt/root/usr/bin
cp ./install-kodi.sh  /mnt/root/usr/bin

# not sure why it doesn't keep the permissions
chmod 755 /mnt/root/usr/bin/install-kodi.sh

chroot /mnt/root /usr/bin/install-kodi.sh

exit
