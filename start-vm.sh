#!/bin/bash

set -Eeuxo pipefail

MACHINE_NAME="test"
QEMU_IMG0="${MACHINE_NAME}_0.img"
QEMU_IMG1="${MACHINE_NAME}_1.img"
QEMU_IMG2="${MACHINE_NAME}_2.img"
QEMU_IMG3="${MACHINE_NAME}_3.img"
QEMU_IMG4="${MACHINE_NAME}_4.img"
SSH_PORT="5555"
OVMF_CODE="/usr/share/OVMF/OVMF_CODE_4M.ms.fd"
OVMF_VARS_ORIG="/usr/share/OVMF/OVMF_VARS_4M.ms.fd"
OVMF_VARS="$(basename "${OVMF_VARS_ORIG}")"

if [ ! -e "${QEMU_IMG0}" ]; then
        qemu-img create -f qcow2 "${QEMU_IMG0}" 8G
fi
if [ ! -e "${QEMU_IMG1}" ]; then
        qemu-img create -f qcow2 "${QEMU_IMG1}" 8G
fi
if [ ! -e "${QEMU_IMG2}" ]; then
        qemu-img create -f qcow2 "${QEMU_IMG2}" 8G
fi
if [ ! -e "${QEMU_IMG3}" ]; then
        qemu-img create -f qcow2 "${QEMU_IMG3}" 8G
fi
if [ ! -e "${QEMU_IMG4}" ]; then
        qemu-img create -f qcow2 "${QEMU_IMG4}" 8G
fi

if [ ! -e "${OVMF_VARS}" ]; then
        cp "${OVMF_VARS_ORIG}" "${OVMF_VARS}"
fi

qemu-system-x86_64 \
        -enable-kvm \
        -cpu host -smp cores=4,threads=1 -m 4096 \
        -object rng-random,filename=/dev/urandom,id=rng0 \
        -device virtio-rng-pci,rng=rng0 \
        -name "${MACHINE_NAME}" \
        -drive file="${QEMU_IMG0}",if=virtio,index=0,format=qcow2 \
        -drive file="${QEMU_IMG1}",if=virtio,index=1,format=qcow2 \
        -drive file="${QEMU_IMG2}",if=virtio,index=2,format=qcow2 \
        -drive file="${QEMU_IMG3}",if=virtio,index=3,format=qcow2 \
        -drive file="${QEMU_IMG4}",if=virtio,index=4,format=qcow2 \
        -net nic,model=virtio -net user,hostfwd=tcp::${SSH_PORT}-:22 \
        -vga virtio \
	-machine q35,smm=on \
        -global driver=cfi.pflash01,property=secure,value=on \
        -drive if=pflash,format=raw,unit=0,file="${OVMF_CODE}",readonly=on \
        -drive if=pflash,format=raw,unit=1,file="${OVMF_VARS}" \
	-usb \
	-device usb-ehci,id=ehci \
	-nographic \
        $@
