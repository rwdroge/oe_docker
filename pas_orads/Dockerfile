# Oracle client stage
FROM ubuntu:22.04 AS oracle

USER 0

RUN mkdir /install/ && \
    mkdir -p /opt/oracle && \
    mkdir -p /opt/oraInventory && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Place Oracle client installer in binaries directory
# Example: binaries/oracle/LINUX.X64_193000_client_home.zip
COPY binaries/oracle/LINUX.X64_193000_client_home.zip /install/ 

WORKDIR /install

RUN unzip LINUX.X64_193000_client_home.zip -d /opt/oracle/client && \
    rm -rf /install/*

WORKDIR /opt/oracle/client/lib
RUN rm -rf libexpat.so.1 && \
    ln -s libexpat.so.1.6.8 libexpat.so.1 && \
    ldconfig /opt/oracle/client/lib

# Build on top of pas_base and add Oracle client
FROM rdroge/oe_pas_base:latest

LABEL maintainer="Ruben Dröge <rdroge@progress.com>"

USER root

# Install Oracle dependencies and create Oracle users/groups
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    libaio1 \
    libaio-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && groupadd -g 54321 oinstall \
  && groupadd -g 54322 dba \
  && groupadd -g 54323 oper \
  && useradd -g oinstall oracle

# Copy Oracle client from oracle stage
COPY --from=oracle --chown=oracle:oinstall /opt/oracle /opt/oracle
COPY --from=oracle --chown=oracle:oinstall /opt/oraInventory /opt/oraInventory

# Set Oracle permissions
RUN chmod -R 775 /opt

# Optional: Copy tnsnames.ora if you have one
# COPY pas_orads/tnsnames.ora /opt/oracle/client/network/admin/tnsnames.ora

USER openedge

# Inherit CMD from pas_base
