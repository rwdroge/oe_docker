# Stage 1: Install OpenEdge
FROM ubuntu:22.04 AS install

ARG CTYPE
ARG OEVERSION

ENV JAVA_HOME=/opt/java/openjdk
COPY --from=eclipse-temurin:JDKVERSION $JAVA_HOME $JAVA_HOME
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Add OpenEdge installer files
ADD installer/PROGRESS_OE.tar.gz /install/openedge/
ADD installer/PROGRESS_PATCH_OE.tar.gz /install/patch/
ADD scripts/install-oe.sh /install/

# Create required directories for version 12.2
RUN if [ "${OEVERSION}" = "122" ] ; then mkdir /etc/progress; else echo "false" ; fi && \
    if [ "${OEVERSION}" = "122" ] ; then mkdir /etc/openedge; else echo "false" ; fi && \
    if [ "${OEVERSION}" = "122" ] ; then touch /etc/openedge.d; else echo "false" ; fi 

COPY pas_orads/response*.ini /install/openedge/
ENV TERM=xterm

# Install OpenEdge and clean up unnecessary files
COPY scripts/clean-oe-files.sh /install/openedge/clean-oe-files.sh 
RUN /install/install-oe.sh && \
    cat /install/install_oe.log && \
    rm /usr/dlc/progress.cfg && \
    /install/openedge/clean-oe-files.sh ${CTYPE} && \
    rm -rf /install

# Stage 2: Install Oracle client
FROM ubuntu:22.04 AS oracle

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

# Stage 3: Final runtime image
FROM ubuntu:22.04 AS runtime

LABEL maintainer="Ruben Dröge <rdroge@progress.com>"

# Install runtime dependencies
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    net-tools \
    netbase \
    libaio1 \
    libaio-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && groupadd -g 1000 openedge \
  && useradd -m -r -u 1000 -g openedge openedge \
  && groupadd -g 54321 oinstall \
  && groupadd -g 54322 dba \
  && groupadd -g 54323 oper \
  && useradd -g oinstall oracle

# Set environment variables
ENV JAVA_HOME=/opt/java/openjdk
ENV DLC=/usr/dlc
ENV WRKDIR=/usr/wrk
ENV TERM=xterm
ENV PATH="${DLC}:${DLC}/bin:${JAVA_HOME}/bin:${PATH}"
ENV LD_LIBRARY_PATH=/opt/oracle/client/lib
ENV ORACLE_HOME=/opt/oracle/client

# Copy Java from install stage
COPY --from=install $JAVA_HOME $JAVA_HOME

# Copy OpenEdge from install stage
COPY --from=install --chown=openedge:openedge $DLC $DLC
COPY --from=install --chown=openedge:openedge $WRKDIR $WRKDIR
COPY --from=install /etc/openedge.d /etc/openedge.d
COPY --from=install /etc/openedge /etc/openedge
COPY --from=install /etc/progress /etc/progress

# Copy Oracle client from oracle stage
COPY --from=oracle --chown=oracle:oinstall /opt/oracle /opt/oracle
COPY --from=oracle --chown=oracle:oinstall /opt/oraInventory /opt/oraInventory

# Set permissions
WORKDIR /usr/dlc/bin
RUN chown root _* && \
    chmod 4755 _* && \
    chown -R openedge:openedge $DLC/servers/pasoe && \ 
    chmod 775 $DLC && \
    chmod 777 $WRKDIR && \
    touch /usr/dlc/progress.cfg  && \
    chown openedge:openedge /usr/dlc/progress.cfg && \
    chmod -R 775 /opt && \
    ldconfig /opt/oracle/client/lib && \
    echo 'tcp    6 TCP' >> /etc/protocols

# Optional: Copy tnsnames.ora if you have one
# COPY pas_orads/tnsnames.ora /opt/oracle/client/network/admin/tnsnames.ora

# Note: No PASOE instance is created here - Pro2 installer will handle that
# Remove progress.cfg after setup
USER openedge
RUN rm /usr/dlc/progress.cfg

VOLUME /usr/dlc/progress.cfg

WORKDIR /usr/dlc

USER root
