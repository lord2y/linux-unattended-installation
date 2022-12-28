#!/bin/bash

COUNTER=1
MACHINE_NAME="test"
QEMU_IMG="${MACHINE_NAME}"
SSH_PORT="5555"
OVMF_CODE="/usr/share/OVMF/OVMF_CODE_4M.ms.fd"
OVMF_VARS_ORIG="/usr/share/OVMF/OVMF_VARS_4M.ms.fd"
OVMF_VARS="$(basename "${OVMF_VARS_ORIG}")"

 
USAGE="
USAGE: ${0##*/} -rts 

SYNOPSIS:

  -r  --raid_type int <raid type: allowed type 1 and 5>
  -t  --disk-type string <allowed type nvme, sata, virtio>
  -s  --size string <disk size: int followed by MGT>
  -c  --cdrom string <iso name>

EXAMPLES:
  
  To start an instance with RAID1,virtio disk with size of 20G
  use the following example:

      $ ${0##*/} -r 1 -t virtio -s 20G -c mini.iso
"
if [ "$#" == "0" ];
then
  echo "$USAGE"
  exit 1
fi
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -r|--raid_type)
      RAID="$2"
      shift # past argument
      shift # past value
      ;;
    -t|--disk-type)
      DISK_TYPE="$2"
      shift # past argument
      shift # past value
      ;;
    -s|--size)
      SIZE="$2"
      shift # past argument
      shift # past value
      ;;
    -c|--cdrom)
      CDROM="$2"
      shift # past argument
      shift # past value
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done
set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters
case $RAID in
	1)
	NUM_DISK=2
	;;
        5)
	NUM_DISK=4	
	;;
esac

if [ -z $SIZE ];then
	echo "Checking disk size"
	DISK_SIZE=8G
else
	DISK_SIZE=$SIZE
fi

CMD="qemu-system-x86_64 \
        -enable-kvm \
        -cpu host -smp cores=4,threads=1 -m 16384 \
        -object rng-random,filename=/dev/urandom,id=rng0 \
        -device virtio-rng-pci,rng=rng0 \
        -name ${MACHINE_NAME}"
case $DISK_TYPE in
	nvme)
		while [ $COUNTER -le $NUM_DISK ];do
			if [ ! -f "${QEMU_IMG}_nvme_${COUNTER}.img" ]; then
				qemu-img create -f qcow2 "${QEMU_IMG}_nvme_${COUNTER}.img" "$DISK_SIZE"
			fi
			CMD+=" -drive file="${QEMU_IMG}_nvme_${COUNTER}.img",if=none,id=nvm${COUNTER} -device nvme,serial=deadbeef${COUNTER},drive=nvm${COUNTER} "
			COUNTER=$(( $COUNTER+1 ))
		done
		;;
	virtio)
		while [ $COUNTER -le $NUM_DISK ];do
			if [ ! -f "${QEMU_IMG}_virtio_${COUNTER}.img" ]; then
				qemu-img create -f qcow2 "${QEMU_IMG}_virtio_${COUNTER}.img" "$DISK_SIZE"
			fi
			CMD+=" -drive file="${QEMU_IMG}_virtio_${COUNTER}.img",if=virtio,index=${COUNTER},format=qcow2 "
			COUNTER=$(( $COUNTER+1 ))
		done
		;;
	sata)
		if [ $NUM_DISK -gt 3 ];then
			echo "RAID5 not possible with SATA disk"
			exit 2
		else
			while [ $COUNTER -le $NUM_DISK ];do
				if [ ! -f "${QEMU_IMG}_${COUNTER}.img" ]; then
					qemu-img create -f qcow2 "${QEMU_IMG}_${COUNTER}.img" "$DISK_SIZE"
				fi
				CMD+=" -drive file="${QEMU_IMG}_${COUNTER}.img",format=qcow2 "
				COUNTER=$(( $COUNTER+1 ))
			done
		fi
		;;
esac

if [ ! -e "${OVMF_VARS}" ]; then
        cp "${OVMF_VARS_ORIG}" "${OVMF_VARS}"
fi

if [ -z $CDROM ];then
	CMD+="-net nic,model=virtio -net user,hostfwd=tcp::${SSH_PORT}-:22 \
		-vga virtio \
		-machine q35,smm=on \
		-global driver=cfi.pflash01,property=secure,value=on \
		-drive if=pflash,format=raw,unit=0,file="${OVMF_CODE}",readonly=on \
		-drive if=pflash,format=raw,unit=1,file="${OVMF_VARS}" \
		-usb \
		-device usb-ehci,id=ehci \
		-nographic"
else
	CMD+="-net nic,model=virtio -net user,hostfwd=tcp::${SSH_PORT}-:22 \
		-vga virtio \
		-machine q35,smm=on \
		-global driver=cfi.pflash01,property=secure,value=on \
		-drive if=pflash,format=raw,unit=0,file="${OVMF_CODE}",readonly=on \
		-drive if=pflash,format=raw,unit=1,file="${OVMF_VARS}" \
		-usb \
		-device usb-ehci,id=ehci \
		-nographic \
		-cdrom ${CDROM}"
fi

$CMD
