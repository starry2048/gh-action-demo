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

# build args
BUILD_FROM               ?=
BUILD_FROM_FLAG           =
ifneq ("$(BUILD_FROM)","")
	BUILD_FROM_FLAG       = --build-arg "from=${BUILD_FROM}"
endif

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

LOAD_FLAG               ?=
ifneq ("$(LOAD_FLAG)","")
	ifeq ("$(PUSH_FLAG)","")
		PUSH_FLAG = --load
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
# variables:
#   BUILD_FROM
#   DOCKER_FILE
#   BUILD_IMAGE_SUFFIX
BUILD_FROM               ?= BASE_RUNTIME
DOCKER_FILE              ?= .
BUILD_IMAGE_PREFIX       ?= 
BUILD_IMAGE_SUFFIX       ?= 


BUILD_FROM_FLAG           =
ifneq ("$(BUILD_FROM)","")
	BUILD_FROM_FLAG       = --build-arg "from=${BUILD_FROM}"
endif


DO_BUILD				  =echo "${DOCKER_BUILD}\n" && ${DOCKER_BUILD}


# DO_TEST_FLAG=echo

.PHONY: all
all: 
	@${DO_BUILD}

# .PHONY: all
# all: build

# .PHONY: test
# test: DO_TEST_FLAG=echo
# test: devel-image

# .PHONY: build
# build: DO_TEST_FLAG=
# build: devel-image

# .PHONY: devel-image
# devel-image:
# 	@${DO_TEST_FLAG} ${DO_BUILD} --tag=${DO_IMAGE_PREFIX}${}${BUILD_IMAGE_SUFFIX} ${DO_FROM}${BUILD_FROM} ${DOCKER_FILE}

