#!/bin/sh

./resize-raspbian.sh $WORK_DIR/$RASPBIAN_VERSION.img 7678
./mount-raspbian.sh $WORK_DIR/$RASPBIAN_VERSION-7678.img
./run-raspbian.sh
./unmount-raspbian.sh
