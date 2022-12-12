FROM ubuntu:22.04

RUN apt-get update && apt-get install -y xorriso p7zip-full wget \
  && mkdir -p autoinstall/{grub,nocloud}

COPY grub.cfg autoinstall/grub/grub.cfg
COPY meta-data autoinstall/server/meta-data
COPY user-data autoinstall/server/user-data

COPY entrypoint.sh /usr/bin/entrypoint.sh

#ENTRYPOINT ["/usr/bin/entrypoint.sh"]
