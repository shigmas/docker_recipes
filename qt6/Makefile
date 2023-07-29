ifndef QT_VERSION
	QT_VERSION = 6.6
endif

build_qt_image: 
	DOCKER_BUILDKIT=1 docker build -t qt.$(QT_VERSION) --build-arg QT_VERSION=$(QT_VERSION) -f Dockerfile .

# Convenience target for creating the patch file.
run_qt_image:
	docker run --rm -it -v $(PWD)/output:/output qt.$(QT_VERSION) /bin/bash
