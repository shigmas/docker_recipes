#!/bin/bash

BOOT_MNT_POINT=/mnt/boot
ROOT_MNT_POINT=/mnt/root

echo "MOUNT RASPBIAN IMAGE: "$1
if [ ! -d $BOOT_MNT_POINT ]; then
    mkdir -p $BOOT_MNT_POINT
fi
if [ ! -d $ROOT_MNT_POINT ]; then
    mkdir -p $ROOT_MNT_POINT
fi

# The boot partition is Id 'c' and Type W95 FAT32
# The root partition is Id '83' and Type Linux
# We'll just use the type to grep to find the line in fdisk
BOOTPARTPATTERN="W95"
ROOTPARTPATTERN="Linux"
# This is a very inefficient way to get the offsets.
BOOT_START=`fdisk -l $1 | grep $BOOTPARTPATTERN | awk '{print $2}'`
BOOT_SECTORS=`fdisk -l $1 | grep $BOOTPARTPATTERN | awk '{print $4}'`
ROOT_START=`fdisk -l $1 | grep $ROOTPARTPATTERN | awk '{print $2}'`
ROOT_SECTORS=`fdisk -l $1 | grep $ROOTPARTPATTERN | awk '{print $4}'`
if [ "$BOOT_START" = "*" ] ; then
    BOOT_START=`fdisk -l $1 | grep $BOOTPARTPATTERN | awk '{print $3}'`
fi
echo "boot start: $BOOT_START, sectors: $BOOT_SECTORS"
echo "root start: $ROOT_START, sectors: $ROOT_SECTORS"

BOOT_OFFSET=$((BOOT_START * 512))
BOOT_LIMIT=$((BOOT_SECTORS * 512))
ROOT_OFFSET=$((ROOT_START * 512))
ROOT_LIMIT=$((ROOT_SECTORS * 512))

mount -o loop,offset=$BOOT_OFFSET,sizelimit=$BOOT_LIMIT $1 $BOOT_MNT_POINT
mount -o loop,offset=$ROOT_OFFSET,sizelimit=$ROOT_LIMIT $1 $ROOT_MNT_POINT

exit
