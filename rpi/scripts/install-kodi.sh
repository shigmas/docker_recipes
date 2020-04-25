#!/bin/sh

locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8
LANG en_US.UTF-8
LC_ALL en_US.UTF-8

apt-get update
apt-get install -y kodi 
