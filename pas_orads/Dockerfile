FROM ubuntu:22.04 AS install

ARG CTYPE
ARG OEVERSION

ENV JAVA_HOME=/opt/java/openjdk
COPY --from=eclipse-temurin:JDKVERSION $JAVA_HOME $JAVA_HOME
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# the running process (i.e. the github action) is responsible for placing the install .tar 
# in the correct location
ADD installer/PROGRESS_OE.tar.gz /install/openedge/
ADD installer/PROGRESS_PATCH_OE.tar.gz /install/patch/
ADD scripts/install-oe.sh /install/

RUN if [ "${OEVERSION}" = "122" ] ; then mkdir /etc/progress; else echo "false" ; fi && \
    if [ "${OEVERSION}" = "122" ] ; then mkdir /etc/openedge; else echo "false" ; fi && \
    if [ "${OEVERSION}" = "122" ] ; then touch /etc/openedge.d; else echo "false" ; fi 

COPY pas_orads/response.ini /install/openedge/response.ini
ENV TERM xterm

COPY scripts/clean-oe-files.sh /install/openedge/clean-oe-files.sh 
# This script needs 'container type' as input parameter as it differs what folders can be removed
RUN /install/install-oe.sh && \
    cat /install/install_oe.log && \
    rm /usr/dlc/progress.cfg && \
    /install/openedge/clean-oe-files.sh ${CTYPE} && \
    rm -rf /install

# Oracle client stage
FROM ubuntu:22.04 AS oracle

USER 0

RUN mkdir /install/ && \
    mkdir -p /opt/oracle && \
    mkdir -p /opt/oraInventory && \
    apt update -y && \
    apt install unzip -y

# Place Oracle client installer in binaries directory
# Example: binaries/oracle/LINUX.X64_193000_client_home.zip
COPY binaries/oracle/LINUX.X64_193000_client_home.zip /install/ 

WORKDIR /install

RUN unzip LINUX.X64_193000_client_home.zip -d /opt/oracle/client 

WORKDIR /opt/oracle/client/lib
RUN rm -rf libexpat.so.1 && \
    ln -s libexpat.so.1.6.8 libexpat.so.1 && \
    ldconfig /opt/oracle/client/lib

# Final instance stage
FROM ubuntu:22.04 AS instance

LABEL maintainer="Ruben Dröge <rdroge@progress.com>"

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    net-tools \
    netbase \
    libaio1 \
    libaio-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd -g 1000 pscadmin \
  && useradd -m -r -u 1000 -g pscadmin pscadmin \
  && groupadd -g 54321 oinstall \
  && groupadd -g 54322 dba \
  && groupadd -g 54323 oper \
  && useradd -g oinstall oracle

ENV JAVA_HOME=/opt/java/openjdk
ENV DLC=/usr/dlc
ENV WRKDIR=/usr/wrk
ENV TERM=xterm
ENV PATH="${DLC}:${DLC}/bin:${JAVA_HOME}/bin:${PATH}"

COPY --from=install $JAVA_HOME $JAVA_HOME
COPY --from=install $DLC $DLC
COPY --from=install $WRKDIR $WRKDIR
COPY --from=install /etc/openedge.d /etc/openedge.d
COPY --from=install /etc/openedge /etc/openedge
COPY --from=install /etc/progress /etc/progress

COPY --from=oracle /opt/oracle /opt/oracle
COPY --from=oracle /opt/oraInventory /opt/oraInventory

WORKDIR /usr/dlc/bin

RUN chown root _* && \
    chmod 4755 _* && \
    chown root:pscadmin $DLC $WRKDIR && \
    chown -R pscadmin:pscadmin $DLC/servers/pasoe && \ 
    chmod 775 $DLC && \
    chmod 777 $WRKDIR && \
    touch /usr/dlc/progress.cfg  && \
    chown pscadmin:pscadmin /usr/dlc/progress.cfg && \
    chown -R oracle:oinstall /opt/oracle && \
    chown -R oracle:oinstall /opt/oraInventory && \
    chmod -R 775 /opt && \
    mkdir -p /app/pas && \
    chown -R pscadmin:pscadmin /app      

WORKDIR /app/pas

USER pscadmin

# create a basic pas instance for production & enable health check
RUN pasman create -p 8220 -P 8221 -s 8222 -Z prod -v prodpas && \
    /app/pas/prodpas/bin/tcman.sh feature HealthCheck=on && \
    chown -R pscadmin:pscadmin /usr/dlc/servers/pasoe /app/pas/prodpas 

USER root

# we need to enable TCP 
RUN echo 'tcp    6 TCP' >> /etc/protocols

# Optional: Copy tnsnames.ora if you have one
# COPY pas_orads/tnsnames.ora /opt/oracle/client/network/admin/tnsnames.ora

COPY pas_orads/start.sh /app/pas/
RUN chmod +x /app/pas/start.sh && \
    chown pscadmin:pscadmin /app/pas/start.sh

USER pscadmin

# Remove progress.cfg after setup
RUN rm /usr/dlc/progress.cfg

VOLUME /usr/dlc/progress.cfg

EXPOSE 8220 8221 8899

WORKDIR /app/pas

CMD ["/app/pas/start.sh"]
