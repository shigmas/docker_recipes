#!/bin/sh

. ./part_common.sh --source-only

IMAGE_NAME=$1
PART_NUM=$2
MOUNT_POINT=$3

part_info=$(get_part_off_size_type $IMAGE_NAME | sort -n)
echo $part_info
if ! test -d $MOUNT_POINT ; then
    mkdir -p $MOUNT_POINT
fi

index=0
for part in $part_info ; do
    part_offset=$(echo $part | cut -d'|' -f1)
    part_sectors=$(echo $part | cut -d'|' -f2)
    part_type=$(echo $part | cut -d'|' -f3)

    if [ $index -eq $PART_NUM ] ; then
        mount -o loop,offset=$(($part_offset * 512)),sizelimit=$(($part_sectors * 512)) $IMAGE_NAME $MOUNT_POINT
    fi
    index=$(($index + 1))
done
