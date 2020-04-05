# Docker Recipes
Docker recipes and tools to run in the image. So, Dockerfiles, and scripts to resize and mount disk images.

I'm not very good with shell scripting, so I don't think code is worth copying, but might be useful to see what it's doing.

## rpi
This one, I built the image, and then by 
1) docker build -t rpi.0 .
2) docker run --rm --privileged=true -it -v /mnt/images:/mnt/images rpi.0 /bin/bash
3) In the container, I build the image then run run-raspbian to set it up:
  - ./mount-raspbian.sh /mnt/image/<image>
  - ./run-rasbian.sh # i use it to install kodi, but you can change it to whatever packages you need
  - I also copy my wpa_supplicant.conf to /mnt/boot and touch /mnt/boot/ssh
  - ./unmount-raspbian.sh


Note:
Loopback devices are used for mounting the images, so you need available loopback devices in /dev. For example, mounting
the image will use 2 loop devices. If there are none available, they're usually created for you. But, if you're running
inside docker, it will fail with "No such file" on both the mounting of the source image and the mounting of the
destination. If you do something on the host that creates the loopbacks (4 will be used: 2 for the source and 2 for the
destination), you don't need to do anything. But, the easiest way might be to run docker (step 2) and pass the /dev
as an additional mount point. Like so:
2) docker run --rm --privileged=true -it -v /mnt/images:/mnt/images -v /dev:/dev rpi.0 /bin/bash
