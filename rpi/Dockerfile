FROM balenalib/armv7hf

RUN apt-get update
# these should be pulled from a file
RUN apt-get install -y wget unzip vim uuid-runtime

COPY rpi/scripts ./

#RUN ./get-rasbian.sh
#RUN ./mount-raspbian.sh /mnt/images/2020-02-13-raspbian-buster.img
#RUN ./run-raspbian.sh
#RUN ./unmount-raspbian.sh
