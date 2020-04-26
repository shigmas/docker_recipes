#!/bin/sh

echo Running build-kodi



./resize-raspbian.sh $DATA_DIR/$RASPBIAN_VERSION.img 4096
rm $DATA_DIR/$RASPBIAN_VERSION.img
./mount-raspbian.sh $DATA_DIR/$RASPBIAN_VERSION-4096.img
df -k
./run-raspbian.sh
./unmount-raspbian.sh
