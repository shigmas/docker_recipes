#!/bin/sh

echo Running build-kodi


./resize-raspbian.sh $DATA_DIR/$RASPBIAN_VERSION.img 7678
./mount-raspbian.sh $DATA_DIR/$RASPBIAN_VERSION-7678.img
./run-raspbian.sh
./unmount-raspbian.sh
