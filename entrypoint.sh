#!/bin/bash

: "${BIN_WGET:=$(type -P wget)}"
: "${BIN_XORRISO:=$(type -P xorriso)}"
: "${BIN_7Z:=$(type -P 7z)}"

_ISO="jammy-live-server-amd64.iso"
_SOURCE_ISO_URL="https://cdimage.ubuntu.com/ubuntu-server/jammy/daily-live/current/$_ISO"
_SOURCE="source-files"
_OUTPUT="/output"

# Create the DIR source-files
mkdir -p "$_SOURCE/server"

# Download the ISO
"$BIN_WGET" "$_SOURCE_ISO_URL"

# Explode the ISO
"$BIN_7Z" -y x "$_ISO" -o"$_SOURCE"

#Move directory [BOOT] up
mv "$_SOURCE"/'[BOOT]' ../BOOT


"$BIN_XORRISO" -as mkisofs -r \
  -V 'Ubuntu 22.04 LTS AUTO (EFIBIOS)' \
  -o ../ubuntu-22.04-autoinstall.iso \
  --grub2-mbr ../BOOT/1-Boot-NoEmul.img \
  -partition_offset 16 \
  --mbr-force-bootable \
  -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b ../BOOT/2-Boot-NoEmul.img \
  -appended_part_as_gpt \
  -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
  -c '/boot.catalog' \
  -b '/boot/grub/i386-pc/eltorito.img' \
    -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
  -eltorito-alt-boot \
  -e '--interval:appended_partition_2:::' \
  -no-emul-boot \
  .

cp -v ../ubuntu-22.04-autoinstall.iso  $_OUTPUT/ubuntu-22.04-autoinstall.iso
