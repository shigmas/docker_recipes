#!/bin/bash

get_extension() {
    PATH=$1
    NEW_ADDITION=$2
    EXT="${PATH##*.}"
    BASE="${PATH%*.*}"

    echo $BASE-$NEW_ADDITION.$EXT
}

get_start_and_sectors() {
    IMG_FILE=$1
    PART_TYPE=$2

    # Grab the 2nd and 4th fields, which are Start and Sectors
    FDISK_OUT=$(fdisk -l $IMG_FILE | awk -v pat="$PART_TYPE" '$0~pat{print $2" "$4}')
    echo $FDISK_OUT
}

get_loopbacks() {
    IMG_NAME=$1
    # we get the loopbacks fro the specified image, and then sort so that the lower offset
    # one comes first. That's assumed to be the boot loopback. 
    AWK_OUT=$(losetup -l | /usr/bin/awk -v pat="$IMG_NAME" '$0~pat{print $3" "$1}' | sort -n | /usr/bin/awk  -v ORS="," '{print $2}')
    echo $AWK_OUT
}

get_partition_id() {
    IMG_NAME=$1
    SFDISK_OUT=$(sfdisk -d $IMG_NAME   | grep label-id | cut -d':' -f2 | cut -d'x' -f2)
    echo $SFDISK_OUT
}
create_resized_file() {
    RESIZED_IMAGE=$1
    BOOT_START=$2
    BOOT_SECTORS=$3
    ROOT_START=$4
    RESIZED_FILE=$5

    PART1="1"
    PART2="2"
    RESIZED1=$RESIZED_IMAGE$PART1
    RESIZED2=$RESIZED_IMAGE$PART2
    if [ -f $RESIZED_FILE ]; then
        rm $RESIZED_FILE
    fi
    # We will calculate the ROOT_SECTORS
    LS_OUT=$(ls -l $RESIZED_IMAGE | awk '{print $5}')
    SECTORS=$((LS_OUT / 512))
    ROOT_SECTORS=$((SECTORS - BOOT_SECTORS))
    # I think these just have to be close enough.
    cat << EOF >> $RESIZED_FILE
label: dos
label-id: 0xbd98648d
device: $RESIZED_NAME.img
unit: sectors
$RESIZED1 : start=        $BOOT_START, size=       $BOOT_SECTORS, type=c
$RESIZED2 : start=        $ROOT_START, size=    $ROOT_SECTORS, type=83
EOF
}

