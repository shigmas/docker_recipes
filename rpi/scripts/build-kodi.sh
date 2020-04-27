#!/bin/sh

echo Running build-kodi



./resize-raspbian.sh $DATA_DIR/$RASPBIAN_VERSION.img $DEST_SIZE
./mount-raspbian.sh $DATA_DIR/$RASPBIAN_VERSION-$DEST_SIZE.img
df -k
echo "Before installation"
./run-raspbian.sh
df -k
echo "After installation"
./unmount-raspbian.sh

echo "Final setup"
./setup-raspbian.sh $DATA_DIR/$RASPBIAN_VERSION-$DEST_SIZE.img $DATA_DIR/wpa_supplicant.conf
