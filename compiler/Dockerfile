FROM ubuntu:24.04 AS install


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
COPY compiler/response.ini /install/openedge/response.ini
ENV TERM=xterm

COPY scripts/clean-oe-files.sh /install/openedge/clean-oe-files.sh 
# This script needs 'container type' as input parameter
RUN /install/install-oe.sh && \
    cat /install/install_oe.log && \
    /usr/dlc/bin/proDebugEnable -enable-all && \
    rm /usr/dlc/progress.cfg && \
    /install/openedge/clean-oe-files.sh ${CTYPE} && \
    rm -rf /install

# multi stage build, this give the possibilty to remove all the slack from stage 0
FROM ubuntu:24.04-minimal AS instance

RUN apt-get update && \
    groupadd -g 980 openedge && \
    useradd -m -r -u 980 -g openedge openedge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


ENV JAVA_HOME=/opt/java/openjdk
ENV DLC=/usr/dlc
ENV WRKDIR=/usr/wrk
ENV TERM=xterm

COPY --from=install $JAVA_HOME $JAVA_HOME
COPY --from=install $DLC $DLC
COPY --from=install $WRKDIR $WRKDIR
COPY --from=install /etc/openedge.d /etc/openedge.d
COPY --from=install /etc/openedge /etc/openedge
COPY --from=install /etc/progress /etc/progress
# allow for progress to be copied into $DLC
# kubernetes does not support volume mount of single files
WORKDIR /usr/dlc/bin
RUN chown root:openedge $DLC $WRKDIR && \
    chmod 775 $DLC && \
    chmod 777 $WRKDIR

# if not present ESAM starts complaining
# this file is necessary in order for a Dockerfile which uses the openedge-pas image to 
# be able to use oeprop.sh to set properties
RUN touch /usr/dlc/progress.cfg  && \
    chown openedge:openedge /usr/dlc/progress.cfg

RUN mkdir -p /app/src /artifacts && \
    chown -R openedge:openedge /app /artifacts

USER openedge

WORKDIR /app/src

LABEL maintainer="Ruben Dröge <rdroge@progress.com>"

ENV PATH="${DLC}:${DLC}/bin:${JAVA_HOME}/bin:${PATH}"