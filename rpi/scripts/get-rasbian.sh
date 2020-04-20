#!/bin/sh

#URLDIR=https://downloads.raspberrypi.org/raspbian_full/images/raspbian_full-2020-02-14
#VERSION_FILE=2020-02-13-raspbian-buster-full
URLDIR=https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2020-02-14
VERSION_FILE=2020-02-13-raspbian-buster-lite
ZIP_FILE=$VERSION_FILE.zip
IMAGE_FILE=$VERSION_FILE.img

wget $URLDIR/$ZIP_FILE

unzip $ZIP_FILE

echo $IMAGE_FILE

