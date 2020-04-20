#!/bin/sh

BOOT_MNT_POINT=/mnt/boot
ROOT_MNT_POINT=/mnt/root

echo "Unmounting and cleaning up"
# This is easy. Just unmount and remove the directories
umount $BOOT_MNT_POINT
rmdir $BOOT_MNT_POINT
umount $ROOT_MNT_POINT
rmdir $ROOT_MNT_POINT

exit
