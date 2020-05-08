# Yocto Builds
I experimented with yocto about 5 years ago, obtained minimal proficiency to build Raspberry Pi and BeagleBone Black images. Then went in a different direction.

So, I'm going to store the steps here, in Dockerfiles, rather than my old method, on Medium, since that's they don't document things from scratch. For instance, I started from a running system, and you may not have the same setup.

Requirements:
 - sato
   - The sato image took up 63G. At least, that's how much space was freed after I deleted it. You should provide yourself with significant wiggle room
   - It took over 12 hours on my 10gen i7
 - qt5-rpi
   
## sato
Dockerfile.sato builds the test image. This will build the test image that the yocto documentation will step through for you. No files to change.

1) Build the image (in the repo root): docker build -t yocto.sato -f yocto/Dockerfile.sato .
2) Make sure you have sufficient space in /opt/yoctoproject, and run the image: docker run  -v /opt/yoctoproject:/opt/yoctoproject --user `id -u` yocto.sato
3) Run the artifact. It's a bit complicated so see the next step

Running the artifact:
1) Clone the source in your container: (Look at the Dockerfile, since this document may get out of date): git clone git://git.yoctoproject.org/poky
2) Source script to set up the environment: source poky/oe-init-build-env /opt/yoctoproject/build
3) Run the image: runqemu /opt/yoctoproject/build/tmp/deploy/images/qemux86-64/core-image-sato-qemux86-64.ext4

## qt5-rpi
An image that runs on the Raspberry Pi with Qt5 (5.13.2 as of this writing). This is more of a work in progress, as opposed to sato, which is just the proof of concept.

1) docker build -t yocto.qt5-rpi -f yocto/Dockerfile.qt5-rpi .
2) docker run -v /opt/build:/opt/build --user `id -u` yocto.qt5-rpi (*)
3) docker run --rm -it -v /opt/build:/opt/build --user `id -u` yocto.qt5-rpi /bin/bash

(*) This has to fetch and build many packages. If it fails, you may need to restart. It keeps track of what it's done, so it will just pick up where it left off, and fix anything that it missed along the way.

If you want the toolchain to compile for the pi, use the same image, but skip 
4) source /opt/yoctoproject/poky-zeus/oe-init-build-env /opt/build/rpi64
5) bitbake meta-toolchain-qt5

As you can see, it uses /opt/build. It is simpler in that you will put the artifact on an SD card rather than running qemu. But that will require a large partition. (100G?)

You will get some warnings, since some things were created in the docker build as root:
WARNING: linux-raspberrypi-1_4.19.93+gitAUTOINC+3fdcc814c5-r0 do_package_qa: QA Issue: linux-raspberrypi: /lib/modules/4.19.93/kernel/drivers/pps/clients/pps-ldisc.ko is owned by gid 0, which is the same as the user running bitbake. This may be due to host contamination [host-user-contaminated]
This should be addressed, but it's not a huge priority.

qtwebkit fails. Tried this:
https://stackoverflow.com/questions/40258161/how-do-i-get-qt-sdk-configured-properly-with-yocto-project
but no success

The main point of this, though, is to have a cross-compiling toolchain with Qt5 to run on the Rapsberry Pi.
