# the Dockerfile for the actual devcontainer

FROM docker.io/progressofficial/oe_compiler:12.8.7
USER root

RUN apt-get update && \
    apt-get install -y xz-utils && \
    apt-get install git -y && \
    apt-get install sudo -y && \
    apt-get install vim -y && \
    apt-get install curl -y && \
    apt-get install wget -y && \
    apt-get install iputils-ping -y && \
    apt-get install net-tools -y && \
    apt-get install dnsutils -y && \
    echo '%sudo ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers ;

ENV JAVA_HOME=/opt/java/openjdk
ENV DLC=/usr/dlc
ENV WRKDIR=/usr/wrk
ENV PATH=$DLC:$DLC/bin:$PATH

USER openedge
# this script is build as docker.io/rdroge/oe_devcontainer:Tag
