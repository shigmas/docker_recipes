#!/bin/bash

echo Running docker image
uname -a
ls /usr/bin/qemu*

./get-rasbian.sh

./mount-raspbian.sh ./2020-02-13-raspbian-buster-lite.img

echo `ls /mnt/root`
echo `ls /mnt/boot`
