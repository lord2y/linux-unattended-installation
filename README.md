# README

This repo aims to provide examples of how to create a self-contained ISO to
perform an unattended installation of Ubuntu Jammy. The Ubuntu server
autoinstall method changed with the release of 20.04. Before that, Ubuntu used
the old Debian pre-seed method. The new autoinstall method uses a “user-data”
file similar in usage to what cloud-init does. The Ubuntu installer, ubiquity,
was modified for this and became subiquity (server ubiquity).  
The autoinstall “user-data” YAML file is a superset of the cloud-init user-data
file and contains directives for the install tool
[Curtin](https://curtin.readthedocs.io/en/latest/topics/overview.html). The only
real guide for what can go in this file is [Automated Server Installs Config
File Reference](https://ubuntu.com/server/docs/install/autoinstall-reference),
and that is not a great reference.  
On the bright side, Ubuntu saves the result of an installation in
`/var/log/installer/autoinstall-user-data`; that file is a user-data YAML file,
and we can use it as a reference.

There are several prerequisites to re-build the ISO; I distilled those in the
Dockerfile, which creates a docker image with all the software we need to unpack
and re-pack the ISO. Along with the software, the docker image carries two
user-data YAML files. Those are two distinct profiles: one provides the config
to automate the installation of a machine with RAID1, whereas the other with
RAID5. The docker image also carries the modified Grub config file that provides
the config to boot the two new profiles.

The `entrypoint.sh` script takes care of unpacking a standard ISO fetched from
the Ubuntu repository, adding to the ISO the use-data files along with the
modified Grub config and finally, building a new ISO. If the operator needs to
add custom deb packages to the ISO, the script can take care of that by picking
those from a specific directory.

## How to use it

First, we need to create the docker image by issuing the following command:

    docker build -t cdrom:1.0 .

We need to create two directories:

    $ mkdir output deb

In the directory output, the script will save the new ISO; in the directory deb,
the operator can save the custom deb files they want to add to the ISO. Please
note is mandatory to have those two directories available before running the
container.

At this point, we can run the following:

    docker run -ti --rm --name cdrom     \
		-v ${PWD}/output:/output  \
		-v --privileged           \
		-v /run/udev:/run/udev:ro \
		-v ${PWD}/deb:/deb      \
		cdrom:1.0

The process will create the file `./output/ubuntu-22.04-autoinstall.iso`. This
repo also provides a script to start a UEFI virtual machine to test the ISO.
Please note that the script does not install the required software but assumes
you have QEMU and OVMF installed on the machine where you run it. To start a
virtual machine with two nvme drives (RAID1), you can run the following command:

     $ ./start-vm.sh -r 1 -t nvme -s 20G -c ubuntu-22.04-autoinstall.iso    

If you do not specify the size of the drives, the script will use the default
value of 8 GiB. Please note that the user-data config file for both profiles
splits the drive into two partitions: `564133888` bytes for `/boot/efi` and one
of `8023703552` bytes for `/`. If you want to change the size of `/`, you have
to pick the size of your drive and subtract `629145600` bytes from it. For
instance, if you have a drive of 20 GiB, you can subtract `629145600` bytes from
it: `21474836480 - 629145600 = 20845690880`. Now, You can replace `8023703552` 
with `20845690880` in the user-data YAML file. This configuration will use the
correct size of your disk; however, the installer will create a `/` filesystem
of only 8 GiB (or the equivalent for the RAID5 config). To fix that, you can run
the following commands after the first boot:

     $ sudo growpart /dev/md127 1
     $ sudo resize2fs /dev/md127p1

The latter commands are valid for both profiles.  

To log in, you can use the following credential: 

 - user: **ubuntu** 
 - password: **ubuntu**

To generate a new hashed password, you can use the command:

     $ mkpasswd --method=SHA-512

