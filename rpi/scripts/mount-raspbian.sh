#!/bin/bash

. ./functions.sh --source-only

BOOT_MNT_POINT=/mnt/boot
ROOT_MNT_POINT=/mnt/root

INPUT_IMAGE=$1
echo "MOUNT RASPBIAN IMAGE: "$INPUT_IMAGE
if [ ! -d $BOOT_MNT_POINT ]; then
    mkdir -p $BOOT_MNT_POINT
fi
if [ ! -d $ROOT_MNT_POINT ]; then
    mkdir -p $ROOT_MNT_POINT
fi

START_SECTORS=$( get_start_and_sectors $INPUT_IMAGE W95 )
BOOT_START=$(echo $START_SECTORS | cut -f1 -d' ')
BOOT_SECTORS=$(echo $START_SECTORS | cut -f2 -d' ')

START_SECTORS=$( get_start_and_sectors $INPUT_IMAGE Linu )
ROOT_START=$(echo $START_SECTORS | cut -f1 -d' ')
ROOT_SECTORS=$(echo $START_SECTORS | cut -f2 -d' ')
echo "boot start: $BOOT_START, sectors: $BOOT_SECTORS"
echo "root start: $ROOT_START, sectors: $ROOT_SECTORS"

BOOT_OFFSET=$((BOOT_START * 512))
BOOT_LIMIT=$((BOOT_SECTORS * 512))
ROOT_OFFSET=$((ROOT_START * 512))
ROOT_LIMIT=$((ROOT_SECTORS * 512))

mount -o loop,offset=$BOOT_OFFSET,sizelimit=$BOOT_LIMIT $INPUT_IMAGE $BOOT_MNT_POINT
mount -o loop,offset=$ROOT_OFFSET,sizelimit=$ROOT_LIMIT $INPUT_IMAGE $ROOT_MNT_POINT

exit
