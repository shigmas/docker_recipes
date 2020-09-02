#!/bin/sh

. ./part_common.sh --source-only

# Example:
# sudo ./update_rpi_diskid.sh <old_image> <new_image>
# If we copied an image, we will still have the old disk label-id in a few places. This script is used
# to update the raspberry pi system where the old label-id is being used.
# NOTE: The standard raspbian or rasppi OS has one boot partition and one root partition. But, all
# linux partitions will be updated.
#
# What will be done:
# The boot partition's cmdline.txt will be updated, replacing PARTUUID's value
# All /etc/fstab files in each linux partition will be updated, replacing the PARTUUID mount.
#
# Parameters:
#  - source image
#  - destination image
HELP="\
Replace the label-id from the source image and update the destination image with the destination image's
label-id.
copy a drive or image file. Of course, for an existing image file, cp is more \
efficient. Use additional parameters if you want to do more.\
"
if [ "$#" -ne 2 ] ; then
    echo $HELP
    exit
fi

SOURCE_IMAGE=$1
DEST_IMAGE=$2

TMP_MOUNT_POINT=/mnt/updater_mount

label_id=$(get_image_info $SOURCE_IMAGE label-id)
# Strip the leading 0x
orig_label_id=$(echo $label_id | sed -r 's/^.{2}//')
label_id=$(get_image_info $DEST_IMAGE label-id)
# Strip the leading 0x
dest_label_id=$(echo $label_id | sed -r 's/^.{2}//')

dest_part_info=$(get_part_off_size_type $DEST_IMAGE)

update_root_partition() {
    orig_label=$1
    shift
    dest_label=$1
    shift

    sed -i "s/${orig_label}/${dest_label}/" $TMP_MOUNT_POINT/etc/fstab
}

update_boot_partition() {
    orig_label=$1
    shift
    dest_label=$1
    shift

    sed -i "s/${orig_label}/${dest_label}/" $TMP_MOUNT_POINT/cmdline.txt
}

mkdir -p $TMP_MOUNT_POINT
part_info=$(get_part_off_size_type $DEST_IMAGE | sort -n)
for part in $part_info ; do
    part_offset=$(echo $part | cut -d'|' -f1)
    part_sectors=$(echo $part | cut -d'|' -f2)
    part_type=$(echo $part | cut -d'|' -f3)

    mount -o loop,offset=$(($part_offset * 512)),sizelimit=$(($part_sectors * 512)) $DEST_IMAGE $TMP_MOUNT_POINT
    is_linux=$(is_linux_type $new_part_type)
    if [ $is_linux -eq 1 ] ; then
        update_root_partition $orig_label_id $dest_label_id
    else
        update_boot_partition $orig_label_id $dest_label_id
    fi
    umount $TMP_MOUNT_POINT
done

rmdir $TMP_MOUNT_POINT
