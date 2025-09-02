# the Dockerfile for the actual devcontainer

FROM docker.io/progressofficial/oe_compiler:latest
USER root

# Install system packages and configure sudo in a single layer
RUN apt-get update && \
    apt-get install -y \
        xz-utils \
        git \
        sudo \
        vim \
        curl \
        wget \
        iputils-ping \
        net-tools \
        dnsutils \
        libnss3 \
        libnspr4 \
        libatk1.0-0t64 \
        libatk-bridge2.0-0t64 \
        libcups2t64 \
        libxkbcommon0 \
        libatspi2.0-0t64 \
        libxdamage1 \
        libpango-1.0-0 \
        libcairo2 \
        libasound2t64 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo '%sudo ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    echo 'openedge ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers

USER openedge

# Install Node.js in a single optimized layer
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash - && \
    sudo apt-get install -y nodejs && \
    sudo apt-get clean && \
    sudo rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/opt/java/openjdk
ENV DLC=/usr/dlc
ENV WRKDIR=/usr/wrk
ENV PATH=$DLC:$DLC/bin:$PATH


# this script is build as docker.io/rdroge/oe_devcontainer:Tag
