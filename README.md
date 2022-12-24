# gh-action-demo

buildx
  "Metadata": {
            "LastTagTime": "0001-01-01T00:00:00Z"
        }
BUILDKIT

DOCKER_BUILDKIT=1 docker buildx build --progress=auto --load --label "con.version.git-tag=fecca4b-dev
con.version.build-time=20221224T191228" --tag=ristar20/u20-cuda:cuda11.7-cudnn8-gl-del --build-arg from=ubuntu:20.04 01.gl/