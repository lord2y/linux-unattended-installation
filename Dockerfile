FROM ubuntu:22.04

RUN apt-get update && apt-get install -y xorriso p7zip-full wget

COPY grub.cfg autoinstall/grub/grub.cfg
COPY bastion autoinstall/bastion
COPY dhcp autoinstall/dhcp
COPY vpn autoinstall/vpn

COPY entrypoint.sh /usr/bin/entrypoint.sh

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
