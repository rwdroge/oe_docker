FROM ubuntu:22.04

ARG oe_version_base=12.8
ARG DOCKER_TAG=12.8.9

COPY ./binaries/oe/${oe_version_base}/PROGRESS_OE_${DOCKER_TAG}_LNX_64.tar.gz /binaries/oe/PROGRESS_OE.tar.gz
COPY ./oeinstaller/start.sh /install/start.sh
CMD [ "/install/start.sh" ]

