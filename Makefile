# time args
BUILD_TIME				 ?=`date +'%Y%m%dT%H%M%S'`
BUILD_TIME_S			 ?=`date +'%m%dT%H%M%S'`

# docker args
DOCKER_REGISTRY          ?= docker.io
DOCKER_ORG               ?= $(shell docker info 2>/dev/null | sed '/Username:/!d;s/.* //')
ifeq ("$(DOCKER_ORG)","")
$(warning WARNING: No docker user found using results from whoami)
DOCKER_ORG                = $(shell whoami)
endif

# git args
GIT_STATUS               ?= $(shell git diff --quiet || echo '-dev')
CURRENT_GIT_TAG          ?= $(shell git describe --tags --always)
GIT_TAG                  ?= ${CURRENT_GIT_TAG}${GIT_STATUS}

BUILD_PROGRESS           ?= auto

EXTRA_DOCKER_BUILD_FLAGS ?=

BUILD                    ?= build
# Intentionally left blank
PLATFORMS_FLAG           ?=
PUSH_FLAG                ?=
USE_BUILDX               ?= true
BUILD_PLATFORMS          ?=
WITH_PUSH                ?= 
# Setup buildx flags
ifneq ("$(USE_BUILDX)","")
    BUILD                     = buildx build

    # Only set platforms flags if using buildx
    ifneq ("$(BUILD_PLATFORMS)","")
        PLATFORMS_FLAG            = --platform="$(BUILD_PLATFORMS)"
    endif

    ifeq ("$(WITH_PUSH)","true")
        PUSH_FLAG                 = --push
        DOCKER_TAG_FLAG           = ${DOCKER_VERSION}
    endif
endif

# custom args
DOCKER_FILE              ?= .
DOCKER_VERSION           ?= 
DOCKER_IMAGE_BASE        ?= u20
DOCKER_IMAGE_SUFFIX      ?= -dev
DOCKER_FULL_NAME         ?= $(DOCKER_REGISTRY)/$(DOCKER_ORG)/$(DOCKER_IMAGE_BASE)${DOCKER_IMAGE_SUFFIX}
DOCKER_TAG_FLAG          ?= ${DOCKER_VERSION}_${GIT_TAG}_${BUILD_TIME_S}


DOCKER_LABEL              = --label "con.version.git-tag=${GIT_TAG}" --label "con.version.build-time=${BUILD_TIME}" 

DOCKER_BUILD              = DOCKER_BUILDKIT=1 \
                            docker $(BUILD) \
                                --progress=$(BUILD_PROGRESS) \
                                --load \
                                $(EXTRA_DOCKER_BUILD_FLAGS) \
                                $(PLATFORMS_FLAG) \
                                $(PUSH_FLAG) \
                                ${DOCKER_LABEL} \
                                -t $(DOCKER_FULL_NAME):$(DOCKER_TAG_FLAG) \
								${BUILD_FROM_FLAG} ${DOCKER_FILE}

# base args
CUDA_VERSION              = 11.7.0
CUDNN_VERSION             = 8
BASE_RUNTIME              = ubuntu:20.04
BASE_DEVEL                = nvidia/cuda:$(CUDA_VERSION)-cudnn$(CUDNN_VERSION)-devel-ubuntu20.04


# custom -------
DO_BUILD_TEST=make -f docker.Makefile WITH_PUSH=${WITH_PUSH} test
DO_BUILD				  =${DO_TEST_FLAG} make -f docker.Makefile


# DO_BUILD=DOCKER_BUILDKIT=1 docker $(BUILD) --progress=$(BUILD_PROGRESS) --build-arg "build_time=${BUILD_TIME}"

.PHONY: all
all: build

.PHONY: test
test: DO_TEST_FLAG=echo
test: devel-image

.PHONY: build
build: DO_TEST_FLAG=
build: devel-image

.PHONY: devel-image
devel-image:
	@${DO_BUILD} DOCKER_IMAGE_SUFFIX=-cuda DOCKER_VERSION=cuda11.7-cudnn8-gl BUILD_FROM=ubuntu:20.04 DOCKER_FILE=01.gl/

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""
	@echo "   1. make build            - build all images"
	@echo "   2. make pull             - pull all images"
	@echo "   3. make clean            - remove all images"
	@echo ""

# pull:
#     # @docker pull ros:noetic-ros-core-focal

# push:
#     # @docker push ${DO_REP}-cuda:cuda11.7-cudnn8-gl

    
#     # @docker push ${DO_REP}:ros-desktop-full
#     # @docker push ${DO_REP}:myros
#     # @docker push ${DO_REP}:steam

# clean:
#     # @docker rmi -f ros:noetic-ros-core-focal

