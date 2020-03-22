#!/bin/bash

. ./functions.sh --source-only

INPUT_IMAGE=$1
DESIRED_SIZE=$2

RESIZED_INPUT_FILE="resized.img.txt"

SRC_BOOT=/mnt/boot
SRC_ROOT=/mnt/root

echo "Resizing $INPUT_IMAGE to $DESIRED_SIZE"

RESIZED_IMAGE=$( get_extension $INPUT_IMAGE $DESIRED_SIZE )
echo "Destination image: $RESIZED_IMAGE"

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
mount -o loop,offset=$BOOT_OFFSET,sizelimit=$BOOT_LIMIT $INPUT_IMAGE $SRC_BOOT
mount -o loop,offset=$ROOT_OFFSET,sizelimit=$ROOT_LIMIT $INPUT_IMAGE $SRC_ROOT

echo "Creating empty image $RESIZED_IMAGE"
# create the new image from the given size
dd if=/dev/zero of=$RESIZED_IMAGE bs=1M count=$DESIRED_SIZE

create_resized_file $RESIZED_IMAGE $BOOT_START $BOOT_SECTORS $ROOT_START $RESIZED_INPUT_FILE

sfdisk $RESIZED_IMAGE < $RESIZED_INPUT_FILE

# attach resized image for each partition
echo "Mounting resized image partitions on loopback"
losetup -f $RESIZED_IMAGE -o $BOOT_OFFSET
losetup -f $RESIZED_IMAGE -o $ROOT_OFFSET

LOOPBACKS=$( get_loopbacks $INPUT_IMAGE )
INPUT_BOOT=$(echo $LOOPBACKS | cut -f1 -d,)
INPUT_ROOT=$(echo $LOOPBACKS | cut -f2 -d,)
LOOPBACKS=$( get_loopbacks $RESIZED_IMAGE )
OUTPUT_BOOT=$(echo $LOOPBACKS | cut -f1 -d,)
OUTPUT_ROOT=$(echo $LOOPBACKS | cut -f2 -d,)

#echo "input boot and root loopbacks $INPUT_BOOT, $INPUT_ROOT"
#echo "output boot and root loopbacks $OUTPUT_BOOT, $OUTPUT_ROOT"

echo "Copying src image to dest image"
# block copy each partition of source image to resized image
#echo "dd if=$INPUT_BOOT of=$OUTPUT_BOOT bs=512 count=$BOOT_SECTORS"
#echo "dd if=$INPUT_ROOT of=$OUTPUT_ROOT bs=512 count=$ROOT_SECTORS"
dd if=$INPUT_BOOT of=$OUTPUT_BOOT bs=512 count=$BOOT_SECTORS
dd if=$INPUT_ROOT of=$OUTPUT_ROOT bs=512 count=$ROOT_SECTORS

# resize ext4 volume to fit rootfs partition in resized image
e2fsck -f $OUTPUT_ROOT
resize2fs $OUTPUT_ROOT

# detach the resized images on the loopback
losetup -d $OUTPUT_ROOT
losetup -d $OUTPUT_BOOT

# unmount the source images
umount $SRC_ROOT
umount $SRC_BOOT

# sync to make sure the image has been updated
sync
sfdisk -l $RESIZED_IMAGE

echo "Fixing partition ID's"
ORIG_PARTID=$( get_partition_id $INPUT_IMAGE )
DEST_PARTID=$( get_partition_id $RESIZED_IMAGE )

# recalculate image parameters for mounting resized image
PART1=`sfdisk -d $RESIZED_IMAGE | grep img1`
PART2=`sfdisk -d $RESIZED_IMAGE | grep img2`

OFFS1=`echo $PART1 | cut -d',' -f1 | cut -d'=' -f2`
OFFS2=`echo $PART2 | cut -d',' -f1 | cut -d'=' -f2`
SIZE1=`echo $PART1 | cut -d',' -f2 | cut -d'=' -f2`
SIZE2=`echo $PART2 | cut -d',' -f2 | cut -d'=' -f2`

BOOT_SIZE=$((SIZE1))
ROOT_SIZE=$((SIZE2))
BOOT_LIMIT=$((SIZE1 * 512))
ROOT_LIMIT=$((SIZE2 * 512))
BOOT_OFFSET=$((OFFS1 * 512))
ROOT_OFFSET=$((OFFS2 * 512))

echo "boot partition size=$BOOT_SIZE (blocks), $BOOT_LIMIT (bytes), offset=$OFFS1 (blocks), $BOOT_OFFSET (bytes)"
echo "root partition size=$ROOT_SIZE (blocks), $ROOT_LIMIT (bytes), offset=$OFFS2 (blocks), $ROOT_OFFSET (bytes)"

# Should be finished, so let's mount
mount -o loop,offset=$BOOT_OFFSET,sizelimit=$BOOT_LIMIT $RESIZED_IMAGE $SRC_BOOT
mount -o loop,offset=$ROOT_OFFSET,sizelimit=$ROOT_LIMIT $RESIZED_IMAGE $SRC_ROOT

# fixup post-resize partition IDs for next bootup
sed -i "s/${PARTID}/${DISKID}/g" $SRC_ROOT/etc/fstab
sed -i "s/${PARTID}/${DISKID}/"  $SRC_BOOT/cmdline.txt

umount $SRC_ROOT
umount $SRC_BOOT
rmdir $SRC_ROOT
rmdir $SRC_BOOT
