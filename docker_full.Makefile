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

# need set ------------
# 
# DOCKER_IMAGE_SUFFIX
# DOCKER_VERSION
# DOCKER_FILE
# --------------------


# custom args
DOCKER_FILE              ?= .
DOCKER_VERSION           ?= 
DOCKER_IMAGE             ?= u20
DOCKER_IMAGE_SUFFIX      ?= -dev
DOCKER_FULL_NAME         ?= $(DOCKER_REGISTRY)/$(DOCKER_ORG)/$(DOCKER_IMAGE)${DOCKER_IMAGE_SUFFIX}
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

all:
	@${DOCKER_BUILD}

test:
	@echo ${DOCKER_BUILD}

# @echo "---------"
# @echo WITH_PUSH: ${WITH_PUSH}
# @echo CURRENT_GIT_TAG: ${CURRENT_GIT_TAG}
# @echo GIT_TAG: ${GIT_TAG}

