FROM ubuntu:latest

ARG BRANCH=master
ARG GITHUB_TOKEN

ENV DVAR default

#RUN apt update && apt install -y git ssh-client wget
RUN if test $GITHUB_TOKEN ; then echo $GITHUB_TOKEN ; else echo alt_${GITHUB_TOKEN}_method ; fi
RUN echo "using ${BRANCH}"

WORKDIR /opt/go

RUN `date --rfc-3339=seconds | tr ' ' '_' > date.out`

COPY ubuntu/scripts/foo.sh .

# This expects to be run with the SSH_IDENTITY environment variable so we can check out
# from github.
# docker run -privileged=true -v :~/.ssh:.ssh -e .ssh/<your github key> <image tag>
CMD ./foo.sh