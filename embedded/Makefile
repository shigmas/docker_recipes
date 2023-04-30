TOOLCHAIN_IMAGE_VERSION=crosstool.001
UBOOT_IMAGE_VERSION=uboot.001
TOOLCHAIN=arm-cortex_a8-linux-gnueabi

# Actually, only master seems to work.
ifndef CROSSTOOL_VERSION
#	CROSSTOOL_VERSION=crosstool-ng-1.25.0
	CROSSTOOL_VERSION=master
endif

build_toolchain_image:
ifndef TOOLCHAIN
	@printf "TOOLCHAIN required\n"
	false
endif
	DOCKER_BUILDKIT=1 docker build -t $(TOOLCHAIN_IMAGE_VERSION) --build-arg TOOLCHAIN=$(TOOLCHAIN) --build-arg CROSSTOOL_VERSION=$(CROSSTOOL_VERSION) -f Dockerfile.cross .

run_toolchain_image:
	docker run -it -v $(PWD)/output:/output $(TOOLCHAIN_IMAGE_VERSION) /bin/bash

build_uboot_image:
ifndef TOOLCHAIN
	@printf "TOOLCHAIN required\n"
	false
endif
	DOCKER_BUILDKIT=1 docker build -t $(UBOOT_IMAGE_VERSION) --build-arg TOOLCHAIN=$(TOOLCHAIN) --build-arg UBOOT_VERSION=$(UBOOT_VERSION) -f Dockerfile.uboot .

run_uboot_image:
	docker run -it -v $(PWD)/output:/output $(UBOOT_IMAGE_VERSION) /bin/bash
