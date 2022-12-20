# vim:set ft=dockerfile:

FROM ubuntu:22.04
ENV EDITOR vim
ENV LANG C.UTF-8

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \ 
   && apt-get install -y -q \
   xorriso \
   p7zip-full \
   wget \
   git \ 
   python3-pip \
   python3-debian \ 
   python3-yaml \
   udev \
   apt-utils \
   initramfs-tools-core \
   squashfs-tools \
   && apt-get autoremove -y \
   && apt-get clean \
   && rm -rf /var/lib/apt/lists/*

COPY grub.cfg autoinstall/grub/grub.cfg
COPY raid1 autoinstall/raid1
COPY raid5 autoinstall/raid5

COPY entrypoint.sh /usr/bin/entrypoint.sh

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
