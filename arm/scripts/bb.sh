#!/bin/bash

BBURL=https://busybox.net/downloads/busybox-1.31.1.tar.bz2
BBZIP=$(basename "$BBURL")
BBTAR="${BBZIP%*.*}"
BBDIR="${BBTAR%*.*}"
echo $BBZIP
echo $BBTAR
echo $BBDIR

wget $BBURL && tar xjf $BBZIP
cd $BBDIR
make defconfig && LDFLAGS="--static" make -j 4
cd -
