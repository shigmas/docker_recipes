
build_reterminal_image:
	DOCKER_BUILDKIT=1 docker build -t reterminal -f Dockerfile.reterm_buildroot .

run_reterminal_image:
	docker run -it -v $(PWD)/output:/output reterminal /bin/bash
