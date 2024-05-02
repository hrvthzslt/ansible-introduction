FROM ubuntu:22.04

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y python3 python3-apt ansible sshpass inetutils-ping

RUN mkdir /root/.ssh && chmod 0700 /root/.ssh

ENTRYPOINT ["tail", "-f", "/dev/null"]
