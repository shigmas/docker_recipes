FROM balenalib/armv7hf

# Nothing arch specific, but just seeing if it works
RUN [ "cross-build-start" ]

RUN apt-get update && apt-get install wget unzip apt-utils && apt-get upgrade build-essential gcc

RUN uname -a
RUN /bin/ls

RUN [ "cross-build-end" ]

WORKDIR /var/mode

COPY arm/scripts/* ./
COPY rpi/scripts/* ./

CMD [ "./build.sh"]
