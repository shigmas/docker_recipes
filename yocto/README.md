# Yocto Builds
I experimented with yocto about 5 years ago, obtained minimal proficiency to build Raspberry Pi and BeagleBone Black images. Then went in a different direction.

So, I'm going to store the steps here, in Dockerfiles, rather than my old method, on Medium, since that's they don't document things from scratch. For instance, I started from a running system, and you may not have the same setup.

Requirements:
 - sato
   - The sato image took up 63G. At least, that's how much space was freed after I deleted it. You should provide yourself with significant wiggle room
   - It took over 12 hours on my 10gen i7

## sato
Dockerfile.sato builds the test image. This will build the test image that the yocto documentation will step through for you. No files to change.

1) Build the image (in the repo root): docker build -t yocto.sato -f yocto/Dockerfile.sato .
2) Make sure you have sufficient space in /opt/yoctoproject, and run the image: docker run  -v /opt/yoctoproject:/opt/yoctoproject --user `id -u` yocto.sato
3) Run the artifact. It's a bit complicated so see the next step

Running the artifact:
1) Clone the source in your container: (Look at the Dockerfile, since this document may get out of date): git clone git://git.yoctoproject.org/poky
2) Source script to set up the environment: source poky/oe-init-build-env /opt/yoctoproject/build
3) Run the image: runqemu /opt/yoctoproject/build/tmp/deploy/images/qemux86-64/core-image-sato-qemux86-64.ext4

