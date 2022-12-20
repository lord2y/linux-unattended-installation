#!/bin/bash

: "${BIN_WGET:=$(type -P wget)}"
: "${BIN_XORRISO:=$(type -P xorriso)}"
: "${BIN_7Z:=$(type -P 7z)}"

LIVEFS_EDITOR="${LIVEFS_EDITOR-$(readlink -f "$(dirname $(dirname ${0}))/livefs-editor")}"
[ -d $LIVEFS_EDITOR ] || git clone https://github.com/mwhudson/livefs-editor $LIVEFS_EDITOR

LIVEFS_EDITOR=$(readlink -f $LIVEFS_EDITOR)
echo $LIVEFS_EDITOR

_ISO="jammy-live-server-amd64.iso"
_SOURCE_ISO_URL="https://cdimage.ubuntu.com/ubuntu-server/jammy/daily-live/current/$_ISO"
_SOURCE="source-files"
_OUTPUT="/output"
_PROFILES=(bastion dhcp vpn)

# Create the DIR source-files
mkdir -p "$_SOURCE"/{bastion,dhcp,vpn}

if [ ! -f "$_ISO" ];then
	# Download the ISO
	"$BIN_WGET" "$_SOURCE_ISO_URL"
fi

# Explode the ISO
"$BIN_7Z" -y x "$_ISO" -o"$_SOURCE"

#Move directory [BOOT] up
mv "$_SOURCE"/'[BOOT]' ../BOOT

#Copy files
cp -v autoinstall/grub/grub.cfg "$_SOURCE"/boot/grub/grub.cfg
for profile in "${_PROFILES[@]}";
do
	cp -v autoinstall/"$profile"/* "$_SOURCE/$profile"

done
cd "$_SOURCE"
"$BIN_XORRISO" -as mkisofs -r \
  -V 'Ubuntu 22.04 LTS AUTO (EFIBIOS)' \
  -o $_OUTPUT/ubuntu-22.04-autoinstall-tmp.iso \
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

#cp -v ../ubuntu-22.04-autoinstall.iso  $_OUTPUT/ubuntu-22.04-autoinstall.iso
mount -t tmpfs tmpfs /tmp
cd "$LIVEFS_EDITOR"
git apply /patch/livefs.patch
cd /
PYTHONPATH=$LIVEFS_EDITOR python3 -m livefs_edit $_OUTPUT/ubuntu-22.04-autoinstall-tmp.iso $_OUTPUT/ubuntu-22.04-autoinstall.iso --add-debs-to-pool $_OUTPUT/puppet-omnibus_3.8.5-exo4_amd64.deb 
