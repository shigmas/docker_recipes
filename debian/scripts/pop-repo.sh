#!/bin/sh

DEB_DIR=$1

pkg_has_sig() {
    PKG=$1
    HAS_SIG=$(dpkg-sig -c /mnt/images/hello-0.0.1_amd64.deb | grep -c GOODSIG)
    if [ $HAS_SIG = 1 ]; then
        return 1
    else
        return 0
    fi
}

for pkg in `find "$DEB_DIR" -name \*.deb`; do
    $HAS_SIG=pkg_has_sig $pkg
    if [ $HAS_SIG == 1 ]; then
        
