FROM jenkins/agent:latest-jdk17 AS install

ARG CTYPE=compiler
ARG OEVERSION=128

USER root

# Install Docker CLI (latest stable version)
ENV DOCKERVERSION=27.4.1
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz \
  && tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 \
                 -C /usr/local/bin docker/docker \
  && rm docker-${DOCKERVERSION}.tgz

# Install OpenEdge using standard installation scripts
ADD installer/PROGRESS_OE.tar.gz /install/openedge/
ADD installer/PROGRESS_PATCH_OE.tar.gz /install/patch/
ADD scripts/install-oe.sh /install/

RUN if [ "${OEVERSION}" = "122" ] ; then mkdir -p /etc/progress /etc/openedge && touch /etc/openedge.d; fi

COPY jenkins/agent/response*.ini /install/openedge/
ENV TERM=xterm

COPY scripts/clean-oe-files.sh /install/openedge/clean-oe-files.sh
RUN /install/install-oe.sh && \
    cat /install/install_oe.log && \
    /usr/dlc/bin/proDebugEnable -enable-all && \
    rm -f /usr/dlc/progress.cfg && \
    /install/openedge/clean-oe-files.sh ${CTYPE} && \
    rm -rf /install

# -------------- FINAL IMAGE -------------
FROM jenkins/agent:latest-jdk17

ARG user=jenkins

USER root

ENV DLC=/usr/dlc
ENV WRKDIR=/usr/wrk
ENV TERM=xterm
ENV PATH=/usr/dlc:/usr/dlc/bin:/usr/dlc/ant/bin:$PATH

# Copy Docker CLI from install stage
COPY --from=install /usr/local/bin/docker /usr/local/bin/docker

# Copy OpenEdge installation from install stage
COPY --from=install --chown=root:root $DLC $DLC
COPY --from=install --chown=root:root $WRKDIR $WRKDIR
COPY --from=install /etc/openedge.d /etc/openedge.d
COPY --from=install /etc/openedge /etc/openedge
COPY --from=install /etc/progress /etc/progress

RUN touch /usr/dlc/progress.cfg && \
    chmod 775 $DLC && \
    chmod 777 $WRKDIR

COPY jenkins/agent/start.sh /home/${user}/start.sh
COPY jenkins/agent/binaries/OpenEdge.BusinessLogic.pl /usr/dlc/src/OpenEdge.BusinessLogic.pl

USER ${user}

LABEL maintainer="rdroge@progress.com"
LABEL description="Jenkins agent with OpenEdge and Docker CLI"

CMD [ "/home/jenkins/start.sh" ]
