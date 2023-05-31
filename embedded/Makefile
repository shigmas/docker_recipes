ifeq ($(TARGET),bbb)
TOOLCHAIN = arm-cortex_a8-linux-gnueabi
endif
ifeq ($(TARGET),qemu)
TOOLCHAIN = arm-unknown-linux-gnueabi
endif
ifeq ($(TARGET),rpi)
TOOLCHAIN = aarch64-rpi3-linux-gnu
endif

# When we build our filesystem, we want to use this (we use the "cross" user
# in the very base (cross) image). This is for busybox and for building the
# root filesystem
FS_ROOT=/home/cross/fsroot

# Actually, only master seems to work.
ifndef CROSSTOOL_VERSION
#	CROSSTOOL_VERSION=crosstool-ng-1.25.0
# Checking out from master will result in different versions in the config. So
# we always need a version. And 1.25 has a problem with zlib.
	CROSSTOOL_VERSION=a8cef57
endif

help:
	@printf "Builder for embedded systems.\n"
	@printf "There are three targets:\n"
	@printf "bbb: BeagleBone Black (or compatible)\n"
	@printf "qemu: Generic ARM for testing/verification\n"
	@printf "rpi: Raspberry Pi 4 (Basically, we set the kernel from the\n"
	@printf "     raspberry pi 3 template\n\n"
	@printf "Toolchain: First, you need to build a toolchain. The generic\n"
	@printf "Dockerfile will build for all three with the provided files in\n"
	@printf "the custom directory. There are some other options which you\n"
	@printf "can find in Dockerfile.cross. (I had problems with the release\n"
	@printf "so it uses a recent, working commit. You can try newer ones)\n"
	@printf "U-boot: For bbb and qemu, you can build a U-boot bootloader\n"
	@printf "Dockerfile will build for all three with the provided files in\n"
	@printf "the custom directory.\n"

toolchain_check:
ifndef TOOLCHAIN
	@printf "Could not find TOOLCHAIN for TARGET\n"
	exit 1
endif

build_toolchain_image: toolchain_check
	DOCKER_BUILDKIT=1 docker build -t crosstool.$(TOOLCHAIN) --build-arg TOOLCHAIN=$(TOOLCHAIN) --build-arg CROSSTOOL_VERSION=$(CROSSTOOL_VERSION) -f Dockerfile.cross .

# Convenience target for creating the patch file.
run_toolchain_image: toolchain_check
	docker run --rm -it -v $(PWD)/output:/output crosstool.$(TOOLCHAIN) /bin/bash

build_uboot_image: toolchain_check
	DOCKER_BUILDKIT=1 docker build -t uboot.$(TOOLCHAIN) --build-arg TOOLCHAIN=$(TOOLCHAIN)  -f Dockerfile.uboot_$(TARGET) .

# Convenience for getting the artifacts
run_uboot_image: toolchain_check
	docker run --rm -it -v $(PWD)/output:/output uboot.$(TOOLCHAIN) /bin/bash

build_kernel_image: toolchain_check
	DOCKER_BUILDKIT=1 docker build -t kernel.$(TOOLCHAIN) --build-arg TOOLCHAIN=$(TOOLCHAIN) -f Dockerfile.kernel_$(TARGET) .

export_kernel_image: toolchain_check
	docker run --rm -v $(PWD)/output:/output kernel.$(TOOLCHAIN)

run_kernel_image:
	docker run -it -v $(PWD)/output:/output kernel.$(TOOLCHAIN) /bin/bash

build_rootfs_image: toolchain_check
	DOCKER_BUILDKIT=1 docker build -t rootfs.$(TOOLCHAIN) --build-arg TOOLCHAIN=$(TOOLCHAIN) --build-arg FS_ROOT=$(FS_ROOT) -f Dockerfile.rootfs_$(TARGET) .

export_rootfs_image: toolchain_check
	docker run --rm -v $(PWD)/output:/output rootfs.$(TOOLCHAIN)

run_rootfs_image: toolchain_check
	docker run -it -v $(PWD)/output:/output rootfs.$(TOOLCHAIN) /bin/bash

# There is no root filesystem, but this is a way to see the work so far.
run_qemu_kernel:
	QEMU_AUDIO_DRV=none qemu-system-arm -m 256M -nographic -M versatilepb \
	-kernel output/zImage.qemu \
	-append "console=ttyAMA0,115200 rdinit=/bin/sh" \
	-dtb output/versatile-pb.dtb \
	-initrd output/initramfs.cpio.gz
