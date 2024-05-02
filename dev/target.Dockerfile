FROM ubuntu:22.04

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y openssh-server sudo systemctl

RUN useradd -m -s /bin/bash ansible && \
    echo 'ansible:password' | chpasswd && \
    usermod -aG sudo ansible

RUN mkdir /var/run/sshd

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]

