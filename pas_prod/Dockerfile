FROM ubuntu:22.04 AS install

ARG CTYPE
ARG OEVERSION

ENV JAVA_HOME=/opt/java/openjdk
COPY --from=eclipse-temurin:JDKVERSION $JAVA_HOME $JAVA_HOME
ENV PATH="${JAVA_HOME}/bin:${PATH}"

ADD installer/PROGRESS_OE.tar.gz /install/openedge/
ADD installer/PROGRESS_PATCH_OE.tar.gz /install/patch/
ADD scripts/install-oe.sh /install/

RUN if [ "${OEVERSION}" = "122" ] ; then mkdir /etc/progress; else echo "false" ; fi && \
    if [ "${OEVERSION}" = "122" ] ; then mkdir /etc/openedge; else echo "false" ; fi && \
    if [ "${OEVERSION}" = "122" ] ; then touch /etc/openedge.d; else echo "false" ; fi 

COPY pas_prod/response*.ini /install/openedge/
ENV TERM=xterm

COPY scripts/clean-oe-files.sh /install/openedge/clean-oe-files.sh 
RUN /install/install-oe.sh && \
    cat /install/install_oe.log && \
    rm /usr/dlc/progress.cfg && \
    /install/openedge/clean-oe-files.sh ${CTYPE} && \
    rm -rf /install

FROM ubuntu:22.04 AS instance
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
    mkdir -p /app/pas /app/src /app/lib /app/config /app/logs && \
    chown -R openedge:openedge /app && \
    echo 'tcp    6 TCP' >> /etc/protocols      

WORKDIR /app/pas

USER openedge

RUN pasman create -p 8810 -P 8811 -j 8812 -s 8812 -Z prod -N pas -U openedge -G openedge ./as 

WORKDIR /app/pas/as

RUN bin/oeprop.sh AppServer.Agent.pas.PROPATH="/app/bin,/app/config,/app/lib/logic.pl,/app/dep1,/app/dep2,/app/dep3,/app/dep4,/app/dep5,\${DLC}/tty,\${DLC}/tty/OpenEdge.Core.pl,\${DLC}/tty/netlib/OpenEdge.Net.pl" && \
    touch /app/pas/as.pf && \
    bin/oeprop.sh AppServer.SessMgr.agentStartupParam="-T \"\${catalina.base}/temp\" -pf ./../../as.pf" && \
    bin/oeprop.sh AppServer.SessMgr.pas.agentLogFile="\${catalina.base}/logs/pas.agent.log" && \
    bin/oeprop.sh AppServer.SessMgr.maxAgents=10 && \
    bin/oeprop.sh AppServer.SessMgr.minAgents=2 && \
    bin/oeprop.sh AppServer.SessMgr.numInitialAgents=2 && \
    bin/oeprop.sh AppServer.Agent.pas.numInitialSessions=10 && \
    bin/oeprop.sh AppServer.SessMgr.agentLoggingLevel=2 && \
    bin/oeprop.sh pas.ROOT.WEB.srvrAppMode=production && \
    bin/oeprop.sh pas.ROOT.WEB.srvrDebug=0 && \
    bin/oeprop.sh pas.ROOT.APSV.oepingEnabled=1 && \
    mkdir -p /app/pas/as/webapps/ROOT/WEB-INF/adapters/web/ROOT/ && \
    chown -R openedge:openedge /app/pas/as

COPY pas_prod/config/oeablSecurity-prod.csv /app/pas/as/webapps/ROOT/WEB-INF/oeablSecurity.csv
COPY --chown=openedge:openedge --chmod=755 pas_prod/start.sh /app/pas/start.sh
USER root

VOLUME /app/bin
VOLUME /app/lib
VOLUME /app/config
VOLUME /app/logs

USER openedge

ENV DLC="${DLC}"

RUN /app/pas/as/bin/oeprop.sh AppServer.SessMgr.agentStartupParam="-T \"\${catalina.base}/temp\" -pf /app/config/as.pf" && \
    rm /usr/dlc/progress.cfg

ENV PASWEBHANDLERS=/app/src/webhandlers/ROOT.handlers

WORKDIR /app/pas

LABEL maintainer="Ruben Dröge <rdroge@progress.com>"

CMD ["/app/pas/start.sh"]
