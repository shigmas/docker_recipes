#!/bin/sh

. ./part_common.sh --source-only

# Example:
# sudo ./copy_parts.sh /dev/sda ubuntu.img 3 1 0
# Image copier. This will copy an image from a device or image file to an image
# file.
# Parameters:
#  - image file or device
#  - destination file
#  - (optional) partition index to operate on. I can only imagine that this is the
#    root partition index.
#  - (optional) flag to copy. non-zero to copy
#  - (optional) new size of the partition. 0 is to copy as it is. This could
#    increase or decrease. It is up to the user to make sure it is not deleting
#    data when decreasing. Obviously, the host must have sufficient disk space.
#    The size is in sectors (The value will be used as the size of the partition).
# ./copy_parts.sh /dev/blah 3 0
#
# Things I've hacked because I don't know how to do it otherwise.
#
HELP="\
Copy a device or image file to a destination image file. This can be used to \
copy a drive or image file. Of course, for an existing image file, cp is more \
efficient. Use additional parameters if you want to do more.\
"
if [ "$#" -lt 2 ] || [ "$#" -gt 5 ] ; then
    echo $HELP
    exit
fi

SOURCE_IMAGE=$1
DEST_IMAGE=$2

PART_INDEX=64
if [ "$#" -gt 2 ]; then
    PART_INDEX=$3
fi

COPY_PART_FLAG=0
if [ "$#" -gt 3 ]; then
    COPY_PART_FLAG=$4
fi

PART_NEW_SIZE=0
if [ "$#" -gt 4 ]; then
    PART_NEW_SIZE=$5
fi

get_id_for_type() {
    image_label=$1
    part_type=$2
    # These are found in the sfdisk man page. There are some shortcuts for the GUID's in
    # the gpt section, but they don't seem to work.
    if [ $image_label = "dos" ] ; then
        if [ $part_type = "W95" ] || [ $part_type = "W95_FAT32" ] ; then
            echo "c"
        elif [ $part_type = "EFI_System" ] ; then
            # This isn't really valid for dos, but I think ef would work if it does
            echo "ef"
        elif [ $part_type = "Linux_swap" ] ; then
            echo "82"
        elif [ $part_type = "Linu" ] || [ $part_type = "Linux_" ] || [ $part_type = "Linux_filesystem" ] ; then
            echo "83"
        else
            echo "Failed to get partition type"
            exit -1
        fi
    elif [ $image_label = "gpt" ] ; then
        if [ $part_type = "W95" ] || [ $part_type = "W95_FAT32" ] ; then
            # no GUID for dos, but...
            echo "c"
        elif [ $part_type = "EFI_System" ] ; then
            echo "C12A7328-F81F-11D2-BA4B-00A0C93EC93B"
        elif [ $part_type = "Linux_swap" ] ; then
            echo "0657FD6D-A4AB-43C4-84E5-0933C84B4F4F"
        elif [ $part_type = "Linu" ] || [ $part_type = "Linux_" ] || [ $part_type = "Linux_filesystem" ] ; then
            echo "0FC63DAF-8483-4772-8E79-3D69D8477DE4"
        else
            echo "Failed to get partition type"
            exit -1
        fi
    else
        echo "Unknown partition scheme"
        exit -1
    fi
}

create_new_part_map() {
    p_index=$1
    shift
    p_new_size=$1
    shift
    copy_flag=$1
    shift
    parts_info=$@

    curr_index=0
    # I think this only handles empty space at the beginning.
    current_offset=0
    for part in $parts_info ; do
        part_offset=$(echo $part | cut -d'|' -f1)
        part_sectors=$(echo $part | cut -d'|' -f2)
        part_type=$(echo $part | cut -d'|' -f3)
        #echo $part: off: $part_offset, size: $part_sectors
        # Not sure how to break, but if anything is zero, ...
        if ! test $part_offset || ! test $part_sectors ; then
            break
        fi
        if [ $current_offset -eq 0 ] ; then
            current_offset=$part_offset
        fi
        new_part_size=$part_sectors
        #echo cur $curr_index part $p_index
        if [ $curr_index -eq $p_index ] ; then
            if [ $p_new_size -ne 0 ] ; then
                new_part_size=$p_new_size
            fi
            if [ $copy_flag -ne 0 ] ; then
                # echo out the copied partition and increment the offset
                echo $current_offset"|"$new_part_size"|"$part_type
                current_offset=$(($current_offset + $new_part_size))
            fi
        fi
        echo $current_offset"|"$new_part_size"|"$part_type
        current_offset=$(($current_offset + $new_part_size))
        curr_index=$(($curr_index + 1))
    done
}

create_empty_image_file() {
    image_file=$1
    shift
    image_label=$1
    shift
    new_part_info=$@

    partition_file=/tmp/$image_file.part

    label_id=$(tr -dc 'a-f0-9' < /dev/urandom 2>/dev/null | head -c8)
    
    echo "Write the partition map to $partition_file"
    # First one is > to create it, >> to append
    echo "label: $image_label" > $partition_file
    echo "label-id: Ox$label_id" >> $partition_file
    echo "unit: sectors" >> $partition_file
    index=1
    last_size=0
    for part in $new_part_info ; do
        part_offset=$(echo $part | cut -d'|' -f1)
        part_sectors=$(echo $part | cut -d'|' -f2)
        part_type=$(echo $part | cut -d'|' -f3)
        part_id=$(get_id_for_type $image_label $part_type)
        echo "${image_file}${index} : start= $part_offset, size= $part_sectors, type= $part_id" >> $partition_file
        index=$((index + 1))
        last_size=$(($part_offset + $part_sectors))
    done

    FOUR_MB=$(($((1024 * 1024)) * 4))
    if [ $last_size -gt 0 ] ; then
        # We seem to need a little padding
        last_size=$(($last_size + $FOUR_MB))
        dest_size=$(($((512 * $last_size)) / $FOUR_MB))
        echo "Writing out blank image  $dest_size blocks ($FOUR_MB) to $image_file"
        dd if=/dev/zero of=$image_file bs=4M count=$dest_size
    else
        echo Unable to get last size. Fatal
        exit
    fi

    sfdisk $image_file < $partition_file
    # TBD - remove the partition file
}

loop_parts() {
    image=$1
    shift
    part_map=$@

    for part in $part_map ; do
        part_offset=$(echo $part | cut -d'|' -f1)
        loopback=$(losetup -f)
        losetup -f -o $(($part_offset * 512)) $image
        echo $part"|"$loopback
    done        
}

remove_loops() {
    part_map=$@

    for part in $part_map ; do
        part_loop=$(echo $part | cut -d'|' -f4)
        losetup -d $part_loop
    done
}

image_label=$(get_image_info $SOURCE_IMAGE label)

part_info=$(get_part_off_size_type $SOURCE_IMAGE | sort -n)
echo $part_info
new_part_info=$(create_new_part_map $PART_INDEX $PART_NEW_SIZE $COPY_PART_FLAG $part_info)
echo $new_part_info

create_empty_image_file $DEST_IMAGE $image_label $new_part_info

part_loops=$(loop_parts $SOURCE_IMAGE $part_info)
#echo "Source Partitions and their loopbacks: $part_loop"

new_part_loops=$(loop_parts $DEST_IMAGE $new_part_info)
#echo "Dest Partitions and their loopbacks: $new_part_loop"

# Handling two "arrays" makes using a function difficult, so this is in the main script
dd_index=0
for old_part in $part_loops ; do
    part_offset=$(echo $old_part | cut -d'|' -f1)
    part_sectors=$(echo $old_part | cut -d'|' -f2)
    part_type=$(echo $old_part | cut -d'|' -f3)
    part_loop=$(echo $old_part | cut -d'|' -f4)

    # get the new part. it matches up with the old unless there
    # is a copy involved. Since we're iterating by hand, use cut.
    new_part=$(echo $new_part_loops | cut -f $(($dd_index + 1)) -d ' ')
    new_part_offset=$(echo $new_part | cut -d'|' -f1)
    new_part_sectors=$(echo $new_part | cut -d'|' -f2)
    new_part_type=$(echo $new_part | cut -d'|' -f3)
    new_part_loop=$(echo $new_part | cut -d'|' -f4)

    echo "copying $part_sectors sectors from $part_loop to $new_part_loop"
    dd if=$part_loop of=$new_part_loop bs=4M count=$new_part_sectors

    inc=1
    if [ $COPY_PART_FLAG -ne 0 ] ; then
        if [ $PART_INDEX -eq $dd_index ] ; then
            inc=0
        fi
    fi
    dd_index=$(($dd_index + $inc))
    is_linux=$(is_linux_type $new_part_type)
    if [ $is_linux -eq 1 ] ; then
        e2fsck -f -y $new_part_loop
    fi

done

remove_loops $part_loops
remove_loops $new_part_loops

sync
