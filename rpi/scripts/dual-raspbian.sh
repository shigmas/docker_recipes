#!/bin/sh

# Based on some the resize script and with stuff I learned from
# https://magpi.raspberrypi.org/articles/raspberry-pi-recovery-partition
# Likely, the docker image will need uuid-runtime. maybe parted and kpartx

# INPUT_IMAGE must be set in the environment, likely from docker

DUAL_BOOT=/mnt/boot
DUAL_ROOTFS=/mnt/root
DUAL_RECOVERYFS=/mnt/recovery

create_mounts() {
    for MNT in "$@"
    do
        if [ ! -d $MNT ]; then
            mkdir -p $MNT
        fi
    done
}

unmount_and_clean() {
    for MNT in "$@"
    do
        if [ -d $MNT ]; then
            umount $MNT
            rmdir $MNT
        fi
    done
}

get_start_and_sectors() {
    IMG_FILE=$1
    PART_TYPE=$2

    # Grab the 2nd and 4th fields, which are Start and Sectors
    # Note: We will need to get the $3 field if $2 was * (bootable?)
    FDISK_OUT=$(fdisk -l $IMG_FILE | awk -v pat="$PART_TYPE" '$0~pat{print $2" "$4}')
    echo $FDISK_OUT
}

get_loopbacks() {
    IMG_NAME=$1
    # we get the loopbacks fro the specified image, and then sort so that the lower offset
    # one comes first. That's assumed to be the boot loopback. 
    AWK_OUT=$(losetup -l | /usr/bin/awk -v pat=$IMG_NAME '$0~pat{print $3" "$1}' | sort -n | /usr/bin/awk  -v ORS="," '{print $2}')
    echo $AWK_OUT
}

create_mounts $DUAL_BOOT $DUAL_ROOTFS $DUAL_RECOVERYFS 
DUAL_IMAGE="${INPUT_IMAGE%*.*}"-"dual-boot"."${INPUT_IMAGE#*.*}"
echo "Destination image: $DUAL_IMAGE"

START_SECTORS=$( get_start_and_sectors $INPUT_IMAGE W95 )
BOOT_START=$(echo $START_SECTORS | cut -f1 -d' ')
BOOT_SECTORS=$(echo $START_SECTORS | cut -f2 -d' ')

START_SECTORS=$( get_start_and_sectors $INPUT_IMAGE Linu )
ROOTFS_START=$(echo $START_SECTORS | cut -f1 -d' ')
ROOTFS_SECTORS=$(echo $START_SECTORS | cut -f2 -d' ')

# Double the root sector size, keep the boot the same
DEST_SIZE=$(($BOOT_START + $BOOT_SECTORS +$((2* $ROOTFS_SECTORS))))

# convert to 4MB blocks
DEST_BLOCKS=$(($(($DEST_SIZE * 512)) / 4194304))
echo creating new image: $DEST_BLOCKS 4MB blocks

dd if=/dev/zero of=$DUAL_IMAGE bs=4M count=$DEST_BLOCKS

# Generate the UUID's and partition UUID
UUIDRESTOREFS=$(uuidgen)
UUIDROOTFS=$(uuidgen)
PARTUUID=$(tr -dc 'a-f0-9' < /dev/urandom 2>/dev/null | head -c8)

# Get the start for the new partition
DUAL_IMAGE_BASE="${DUAL_IMAGE##*/}"
RECOVERYFS_START=$((ROOTFS_START + ROOTFS_SECTORS))
echo "sfdisk on resized image with partitioning file"
sfdisk $DUAL_IMAGE <<EOF
#cat <<EOF >> tmp.txt
label: dos
label-id: 0x${PARTUUID}
unit: sectors
${DUAL_IMAGE_BASE}1 : start= ${BOOT_START}, size= ${BOOT_SECTORS}, type=c
${DUAL_IMAGE_BASE}2 : start= ${ROOTFS_START}, size= ${ROOTFS_SECTORS}, type=83
${DUAL_IMAGE_BASE}3 : start= ${RECOVERYFS_START}, size= ${ROOTFS_SECTORS}, type=83
EOF

BOOT_OFFSET=$((BOOT_START * 512))
BOOT_LIMIT=$((BOOT_SECTORS * 512))
ROOTFS_OFFSET=$((ROOTFS_START * 512))
ROOTFS_LIMIT=$((ROOTFS_SECTORS * 512))
RECOVERYFS_OFFSET=$((RECOVERYFS_START * 512))
RECOVERYFS_LIMIT=$((ROOTFS_SECTORS * 512))

echo root: $ROOTFS_OFFSET $ROOTFS_LIMIT $RECOVERYFS_OFFSET $RECOVERYFS_LIMIT

# Mount the source and destination images. I'm not sure why the losetup --show
# doesn't work in this script, so losetup, and then find the devs later
echo "Mounting source and destination image"
losetup -f -o $BOOT_OFFSET $INPUT_IMAGE
losetup -f -o $ROOTFS_OFFSET  $INPUT_IMAGE
INPUT_IMAGE_NAME="${INPUT_IMAGE##*/}"
LOOPBACKS=$( get_loopbacks $INPUT_IMAGE_NAME )
SRC_BOOT_LOOP=$(echo $LOOPBACKS | cut -f1 -d,)
SRC_ROOTFS_LOOP=$(echo $LOOPBACKS | cut -f2 -d,)

losetup -f -o $BOOT_OFFSET $DUAL_IMAGE
losetup -f -o $ROOTFS_OFFSET  $DUAL_IMAGE
losetup -f -o $RECOVERYFS_OFFSET  $DUAL_IMAGE
DUAL_IMAGE_NAME="${DUAL_IMAGE##*/}"
LOOPBACKS=$( get_loopbacks $DUAL_IMAGE )
DEST_BOOT_LOOP=$(echo $LOOPBACKS | cut -f1 -d,)
DEST_ROOTFS_LOOP=$(echo $LOOPBACKS | cut -f2 -d,)
DEST_RECOVERYFS_LOOP=$(echo $LOOPBACKS | cut -f3 -d,)

echo loops: boots: $SRC_BOOT_LOOP $DEST_BOOT_LOOP
echo loops: roots: $SRC_ROOTFS_LOOP $DEST_ROOTFS_LOOP $DEST_RECOVERYFS_LOOP

# Which partition is the root and which is the recovery is arbitrary. But, we'll use
# the "first" partition as root and the "second" as recovery.
dd if=$SRC_BOOT_LOOP of=$DEST_BOOT_LOOP bs=4M
dd if=$SRC_ROOTFS_LOOP of=$DEST_ROOTFS_LOOP bs=4M
dd if=$SRC_ROOTFS_LOOP of=$DEST_RECOVERYFS_LOOP bs=4M

tune2fs $DEST_RECOVERYFS_LOOP -U ${UUIDRESTOREFS}
e2label $DEST_RECOVERYFS_LOOP recoveryfs
tune2fs $DEST_ROOTFS_LOOP -U ${UUIDROOTFS}

# Perform any fixes due to block size
#e2fsck -f $DEST_ROOTFS_LOOP
#resize2fs $DEST_ROOTFS_LOOP
#e2fsck -f $DEST_RECOVERYFS_LOOP
#resize2fs $DEST_RECOVERYFS_LOOP

# Delete the loopbacks and start over with our new image
losetup -d $SRC_BOOT_LOOP $DEST_BOOT_LOOP $SRC_ROOTFS_LOOP $DEST_ROOTFS_LOOP $DEST_RECOVERYFS_LOOP

# recalculate image parameters for mounting dual image
PART1=`sfdisk -l $DUAL_IMAGE | grep img1`
PART2=`sfdisk -l $DUAL_IMAGE | grep img2`
PART3=`sfdisk -l $DUAL_IMAGE | grep img3`

OFFS1=`echo $PART1 | cut -d" " -f2`
OFFS2=`echo $PART2 | cut -d" " -f2`
OFFS3=`echo $PART3 | cut -d" " -f2`
SIZE1=`echo $PART1 | cut -d" " -f4`
SIZE2=`echo $PART2 | cut -d" " -f4`
SIZE3=`echo $PART3 | cut -d" " -f4`

BOOT_SIZE=$((SIZE1))
ROOTFS_SIZE=$((SIZE2))
RECOVERYFS_SIZE=$((SIZE3))
BOOT_LIMIT=$((SIZE1 * 512))
ROOTFS_LIMIT=$((SIZE2 * 512))
RECOVERYFS_LIMIT=$((SIZE3 * 512))
BOOT_OFFSET=$((OFFS1 * 512))
ROOTFS_OFFSET=$((OFFS2 * 512))
RECOVERYFS_OFFSET=$((OFFS3 * 512))

echo $BOOT_SIZE, $BOOT_LIMIT
echo $ROOTFS_SIZE, $ROOTFS_LIMIT
echo $RECOVERYFS_SIZE, $RECOVERYFS_LIMIT

# Mount the partitions on the new image so we can fix the boot and fstabs
mount -o loop,offset=$BOOT_OFFSET,sizelimit=$BOOT_LIMIT $DUAL_IMAGE $DUAL_BOOT
mount -o loop,offset=$ROOTFS_OFFSET,sizelimit=$ROOTFS_LIMIT $DUAL_IMAGE $DUAL_ROOTFS
mount -o loop,offset=$RECOVERYFS_OFFSET,sizelimit=$RECOVERYFS_LIMIT $DUAL_IMAGE $DUAL_RECOVERYFS

# Get the original PARTID and replace it in the dest. (we should verify that this won't
# break our existing cmdline.txt
ORIG_PARTID=$(sfdisk -d $INPUT_IMAGE | grep label-id | cut -d':' -f2 | cut -d'x' -f2)
sed -i "s/${ORIG_PARTID}/${PARTUUID}/"  $DUAL_BOOT/cmdline.txt
# Don't resize. We want both partitions to be equal
sed -i "s/init=\/usr\/lib\/raspi-config\/init_resize.sh//"  $DUAL_BOOT/cmdline.txt

# Create new fstabs, since we need to add a new partition
# XXX - we need to do this more strategically, since we've already modified these.

mkdir $DUAL_ROOTFS/recovery
cat << EOF > $DUAL_ROOTFS/etc/fstab
proc                     /proc  proc    defaults          0       0
PARTUUID=${PARTUUID}-01  /boot  vfat    defaults          0       2
PARTUUID=${PARTUUID}-02  /      ext4    defaults,noatime  0       1
PARTUUID=${PARTUUID}-03  /recovery      ext4    defaults,noatime  0       1
EOF

mkdir $DUAL_RECOVERYFS/recovery
cat << EOF > $DUAL_RECOVERYFS/etc/fstab
proc                     /proc  proc    defaults          0       0
PARTUUID=${PARTUUID}-01  /boot  vfat    defaults          0       2
PARTUUID=${PARTUUID}-02  /recovery      ext4    defaults,noatime  0       1
PARTUUID=${PARTUUID}-03  /      ext4    defaults,noatime  0       1
EOF

#cp /mnt/images/wpa_supplicant.conf /mnt/boot
#touch /mnt/boot/ssh

unmount_and_clean $DUAL_BOOT $DUAL_ROOTFS $DUAL_RECOVERYFS
