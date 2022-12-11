VERSION=$(shell cat docker-buildpack.version)
CF_BUILDPACK_VERSION=$(shell cat cf-buildpack.version)
ROOTFS_VERSION=$(shell cat rootfs.version)
ROOTFS_IMAGES=$(patsubst Dockerfile.rootfs.%, rootfs.%, $(wildcard Dockerfile.rootfs.*))

get-sample:
	if [ -d build ]; then rm -rf build; fi
	if [ -d downloads ]; then rm -rf downloads; fi
	mkdir -p downloads build
	wget https://s3-eu-west-1.amazonaws.com/mx-buildpack-ci/BuildpackTestApp-mx-7-16.mda -O downloads/application.mpk
	unzip downloads/application.mpk -d build/

rootfs.%: Dockerfile.rootfs.%
	docker build \
	-t mendix/rootfs:$* -f Dockerfile.rootfs.$* .

build-base-images: $(ROOTFS_IMAGES)

build-image:
	docker build \
	--build-arg BUILD_PATH=build \
	--build-arg CF_BUILDPACK=$(CF_BUILDPACK_VERSION) \
	--build-arg ROOTFS_IMAGE=$(ROOTFS_VERSION) \
	-t mendix/mendix-buildpack:$(VERSION) .

build-base-image-for-private-net:
	docker build \
	-f Dockerfile.private.base \
	--build-arg BUILD_PATH=build \
	--build-arg CF_BUILDPACK=$(CF_BUILDPACK_VERSION) \
	--build-arg ROOTFS_IMAGE=$(ROOTFS_VERSION) \
	-t mendix/mendix-buildpack-private-net-base:$(VERSION) .

build-image-on-private-net:
	docker build \
	-f Dockerfile.private \
	--build-arg BUILD_PATH=build \
	--build-arg ROOTFS_IMAGE=$(ROOTFS_VERSION) \
	-t mendix/mendix-buildpack-private-net:$(VERSION) .

test-container:
	tests/test-generic.sh tests/docker-compose-postgres.yml
	tests/test-generic.sh tests/docker-compose-sqlserver.yml
	tests/test-generic.sh tests/docker-compose-azuresql.yml

run-container:
	BUILDPACK_VERSION=$(VERSION) docker-compose -f tests/docker-compose-postgres.yml up
