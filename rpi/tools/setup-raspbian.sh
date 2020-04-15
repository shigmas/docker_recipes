#!/bin/bash

. ./functions.sh --source-only

INPUT_IMAGE=$1
WPA_SUPPLICANT=$2

echo "Modifying image $INPUT_IMAGE and wpa_supplicant $WPA_SUPPLICANT"

SRC_BOOT=/mnt/boot
SRC_ROOT=/mnt/root

# Mount
START_SECTORS=$( get_start_and_sectors $INPUT_IMAGE W95 )
BOOT_START=$(echo $START_SECTORS | cut -f1 -d' ')
BOOT_SECTORS=$(echo $START_SECTORS | cut -f2 -d' ')

START_SECTORS=$( get_start_and_sectors $INPUT_IMAGE Linu )
ROOT_START=$(echo $START_SECTORS | cut -f1 -d' ')
ROOT_SECTORS=$(echo $START_SECTORS | cut -f2 -d' ')
BOOT_OFFSET=$((BOOT_START * 512))
BOOT_LIMIT=$((BOOT_SECTORS * 512))
ROOT_OFFSET=$((ROOT_START * 512))
ROOT_LIMIT=$((ROOT_SECTORS * 512))

if [ ! -d $SRC_BOOT ]; then
    mkdir -p $SRC_BOOT
fi
if [ ! -d $SRC_ROOT ]; then
    mkdir -p $SRC_ROOT
fi

# These commands might have errors on Ubuntu. You can ignore these, apparently.
echo "Mounting $INPUT_IMAGE"
mount -o loop,offset=$BOOT_OFFSET,sizelimit=$BOOT_LIMIT $INPUT_IMAGE $SRC_BOOT
mount -o loop,offset=$ROOT_OFFSET,sizelimit=$ROOT_LIMIT $INPUT_IMAGE $SRC_ROOT

echo "Enable ssh"
touch $SRC_BOOT/ssh

# copy the wpa_supplicant so we can connect to the wifi
cp $WPA_SUPPLICANT $SRC_BOOT

# Get the sound to go through HDMI.
sed -i "s/$/ snd_bcm2835.enable_headphones=1 snd_bcm2835.enable_hdmi=1 snd_bcm2835.enable_compat_alsa=0/" $SRC_BOOT/cmdline.txt

sed -i "s/exit 0/export HOME=\/home\/pi\n\n\/usr\/bin\/kodi &\n\nexit 0/g" $SRC_ROOT/etc/rc.local

umount $SRC_ROOT
umount $SRC_BOOT
rmdir $SRC_ROOT
rmdir $SRC_BOOT
