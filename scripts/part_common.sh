#!/bin/sh

get_image_info() {
    image_dev=$1
    image_key=$2

    sfdisk -d $image_dev | {
        while read LINE; do
            case $LINE in
                $image_key*)
                    echo $LINE | awk '{print $2}'
                    break
                    ;;
            esac
        done
    }
}

# Returns 1 if the type matches 
is_linux_type() {
    part_id=$1

    if [ $part_type = "Linu" ] || [ $part_type = "Linux_" ] || [ $part_type = "Linux_filesystem" ] ; then
        echo 1
    else
        echo 0
    fi
}

# echo the partition information in the format:
# partition | offset | size | type
# XXX - we should also get the block size, but I haven't seen it be anything other than 512.
#BLOCK_SIZE=512
get_part_off_size_type() {
    d_dev=$1
    # The columns are different for different kinds of images. e.g. the raspberry pi
    # image shows the type Id, but the ubuntu one does not. Use -o which takes a
    # "list" of columns. But how the heck do you specify columns?
    sfdisk -l $d_dev | {
        inParts=0
        disk_label_type=''
        while read LINE; do
            #echo $LINE
            case $LINE in
                Disklabel*)
                    # Ideally, since this is what get_image_info would do, we'd reuse
                    # that, but since sfdisk | is running in a subprocess, it's tricky
                    # passing information around with anything other than echo, so we'll
                    # just use it here
                    disk_label_type=`echo $LINE | awk '{print $3}'`
                    ;;
                Device*)
                    inParts=1
                    ;;
                $d_dev*)
                    if [ $inParts -eq 1 ] ; then
                        # For the type, it may be more than 2 words, but it's enough
                        # for us to look it up later... If it's a problem, we can
                        # iterate it and just grab the end for the type
                        # dos: MBR lists type
                        # gpt: GUID Partition Table omits it
                        if [ $disk_label_type = "dos" ]; then
                            echo $LINE | awk '{print $2"|"$4"|"$7"_"$8}'
                        elif [ $disk_label_type = "gpt" ]; then
                            echo $LINE | awk '{print $2"|"$4"|"$6"_"$7}'
                        else
                            echo unrecognized disk label: $disk_label_type
                            return
                        fi
                    fi
                    ;;
            esac
        done
    }
}
