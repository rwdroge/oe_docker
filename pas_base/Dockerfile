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

COPY pas_base/response.ini /install/openedge/response.ini
ENV TERM=xterm

COPY scripts/clean-oe-files.sh /install/openedge/clean-oe-files.sh 
# This script needs 'container type' as input parameter as it differs what folders can be removed
RUN /install/install-oe.sh && \
    cat /install/install_oe.log && \
    rm /usr/dlc/progress.cfg && \
    /install/openedge/clean-oe-files.sh ${CTYPE} && \
    rm -rf /install

# multi stage build, this give the possibilty to remove all the slack from stage 0
FROM ubuntu:22.04 AS instance

LABEL maintainer="Ruben Dröge <rdroge@progress.com>"

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    net-tools \
    netbase \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && groupadd -g 1000 openedge \
  && useradd -m -r -u 1000 -g openedge openedge

ENV JAVA_HOME=/opt/java/openjdk
ENV DLC=/usr/dlc
ENV WRKDIR=/usr/wrk
ENV TERM=xterm
ENV PATH="${DLC}:${DLC}/bin:${JAVA_HOME}/bin:${PATH}"

COPY --from=install $JAVA_HOME $JAVA_HOME
COPY --from=install --chown=root:openedge $DLC $DLC
COPY --from=install --chown=root:openedge $WRKDIR $WRKDIR
COPY --from=install /etc/openedge.d /etc/openedge.d
COPY --from=install /etc/openedge /etc/openedge
COPY --from=install /etc/progress /etc/progress

WORKDIR /usr/dlc/bin

RUN chown root _* && \
    chmod 4755 _* && \
    chown -R openedge:openedge $DLC/servers/pasoe && \ 
    chmod 775 $DLC && \
    chmod 777 $WRKDIR && \
    touch /usr/dlc/progress.cfg  && \
    chown openedge:openedge /usr/dlc/progress.cfg && \
    mkdir -p /app/pas && \
    chown -R openedge:openedge /app && \
    echo 'tcp    6 TCP' >> /etc/protocols      

WORKDIR /app/pas

USER openedge

# create a basic pas instance for production & enable health check
RUN pasman create -p 8220 -P 8221 -s 8222 -Z prod -v prodpas && \
    /app/pas/prodpas/bin/tcman.sh feature HealthCheck=on && \
    chown -R openedge:openedge /usr/dlc/servers/pasoe /app/pas/prodpas 

USER root

COPY --chown=openedge:openedge --chmod=755 pas_base/start.sh /app/pas/start.sh

USER openedge

# Remove progress.cfg after setup
RUN rm /usr/dlc/progress.cfg

VOLUME /usr/dlc/progress.cfg

EXPOSE 8220 8221 8899

WORKDIR /app/pas

CMD ["/app/pas/start.sh"]
