UBOOT_IMAGE_VERSION=uboot.001
KERNEL_IMAGE_VERSION=kernel.001

ifeq ($(TARGET),bbb)
TOOLCHAIN = arm-cortex_a8-linux-gnueabi
endif
ifeq ($(TARGET),qemu)
TOOLCHAIN = arm-unknown-linux-gnueabi
endif
ifeq ($(TARGET),rpi)
TOOLCHAIN = aarch64-rpi3-linux-gnu
endif

# Actually, only master seems to work.
ifndef CROSSTOOL_VERSION
#	CROSSTOOL_VERSION=crosstool-ng-1.25.0
# Checking out from master will result in different versions in the config. So
# we always need a version. And 1.25 has a problem with zlib.
	CROSSTOOL_VERSION=a8cef57
endif

build_toolchain_image:
ifndef TOOLCHAIN
	@printf "Could not find TOOLCHAIN for TARGET\n"
	exit
endif
	DOCKER_BUILDKIT=1 docker build -t crosstool.$(TOOLCHAIN) --build-arg TOOLCHAIN=$(TOOLCHAIN) --build-arg CROSSTOOL_VERSION=$(CROSSTOOL_VERSION) -f Dockerfile.cross .

run_toolchain_image:
	docker run -it -v $(PWD)/output:/output crosstool.$(TOOLCHAIN) /bin/bash

build_uboot_image:
ifndef TOOLCHAIN
	@printf "TOOLCHAIN required\n"
	false
endif
	DOCKER_BUILDKIT=1 docker build -t $(UBOOT_IMAGE_VERSION) --build-arg TOOLCHAIN=$(TOOLCHAIN) --build-arg UBOOT_VERSION=$(UBOOT_VERSION) -f Dockerfile.uboot .

run_uboot_image:
	docker run -it -v $(PWD)/output:/output $(UBOOT_IMAGE_VERSION) /bin/bash

build_kernel_image:
ifndef TOOLCHAIN
	@printf "TOOLCHAIN required\n"
	false
endif
	DOCKER_BUILDKIT=1 docker build -t $(KERNEL_IMAGE_VERSION) --build-arg TOOLCHAIN=$(TOOLCHAIN) -f Dockerfile.kernel .

run_kernel_image:
	docker run -it -v $(PWD)/output:/output $(KERNEL_IMAGE_VERSION) /bin/bash

