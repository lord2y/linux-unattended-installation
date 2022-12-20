# README

To create an ISO you have to build the docker container:

    docker build -t cdrom:1.0 .

Create the following directories:

  - debs
  - output

Then you can run the following:

    docker run -ti --rm --name cdrom \ 
        -v ${PWD}/output:/output \ 
	-v ${PWD}/image:/image   \
	--privileged \ 
	-v /run/udev:/run/udev:ro \ 
	-v debs:/debs \
	-v ${PWD}/patch:/patch cdrom:1.0

You'll find the file `ubuntu-22.04-autoinstall.iso` in the directory `./output`.
