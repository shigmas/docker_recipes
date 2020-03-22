# Docker Recipes
Docker recipes and tools to run in the image. So, Dockerfiles, and scripts to resize and mount disk images.

I'm not very good with shell scripting, so I don't think code is worth copying, but might be useful to see what it's doing.

## rpi
This one, I built the image, and then by 
1) docker build -t rpi.0 .
2) docker run --rm --privileged=true -it -v /mnt/images:/mnt/images rpi.0 /bin/bash
3) In the container, I build the image, and then ran the run-raspbian.sh to run the mounted image in chroot mode.
