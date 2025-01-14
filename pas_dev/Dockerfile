FROM ubuntu:22.04 as install

ARG CTYPE

ENV JAVA_HOME=/opt/java/openjdk
COPY --from=eclipse-temurin:JDKVERSION $JAVA_HOME $JAVA_HOME
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# the running process (i.e. the github action) is responsible for placing the install .tar 
# in the correct location
ADD installer/PROGRESS_OE.tar.gz /install/openedge/
ADD installer/PROGRESS_PATCH_OE.tar.gz /install/patch/
ADD scripts/install-oe.sh /install/

COPY compiler/response.ini /install/openedge/response.ini
ENV TERM xterm

RUN /install/install-oe.sh

RUN cat /install/install_oe.log
RUN /usr/dlc/bin/proDebugEnable -enable-all
RUN rm /usr/dlc/progress.cfg

COPY scripts/clean-oe-files.sh /install/openedge/clean-oe-files.sh 
# This script needs 'container type' as input parameter
RUN /install/openedge/clean-oe-files.sh ${CTYPE}

# multi stage build, this give the possibilty to remove all the slack from stage 0
FROM ubuntu:22.04 as instance

ENV JAVA_HOME=/opt/java/openjdk
ENV DLC=/usr/dlc
ENV WRKDIR=/usr/wrk
ENV TERM=xterm

RUN groupadd -g 1000 openedge && \
    useradd -r -u 1000 -g openedge openedge

COPY --from=install $JAVA_HOME $JAVA_HOME
COPY --from=install $DLC $DLC
COPY --from=install $WRKDIR $WRKDIR

# allow for progress to be copied into $DLC
# kubernetes does not support volume mount of single files
RUN chown root:openedge $DLC $WRKDIR && \
    chmod 775 $DLC && \
    chmod 777 $WRKDIR

# if not present ESAM starts complaining
# this file is necessary in order for a Dockerfile which uses the openedge-pas image to 
# be able to use oeprop.sh to set properties
RUN touch /usr/dlc/progress.cfg  && \
    chown openedge:openedge /usr/dlc/progress.cfg
    

RUN mkdir -p /app/pas &&     mkdir /app/src &&     mkdir /app/lib &&     mkdir /app/config && \
    chown -R openedge:openedge /app /artifacts

WORKDIR /app/pas

RUN pasman create -p 8810 -P 8811 -j 8812 -s 8812 -Z dev -f -N pas ./as

WORKDIR /app/pas/as

RUN bin/oeprop.sh AppServer.Agent.pas.PROPATH=".,/app/config,/app/src,/app/lib/logic.pl,/app/dep1,/app/dep2,/app/dep3,/app/dep4,/app/dep5,\${DLC}/tty,\${DLC}/tty/OpenEdge.Core.pl,\${DLC}/tty/netlib/OpenEdge.Net.pl" &&     touch /app/pas/as.pf &&     bin/oeprop.sh AppServer.SessMgr.agentStartupParam="-T \"\${catalina.base}/temp\" -pf ./../../as.pf" &&     bin/oeprop.sh AppServer.SessMgr.pas.agentLogFile="\${catalina.base}/logs/pas.agent.log" && \
    mkdir -p /app/pas/as/webapps/ROOT/WEB-INF/adapters/web/ROOT/

COPY config/oeablSecurity-dev.csv /app/pas/as/webapps/ROOT/WEB-INF/oeablSecurity.csv
COPY start.sh /app/pas/
RUN chmod +x /app/pas/start.sh && \
    chown -R openedge:openedge

USER openedge

VOLUME [/app/src]
VOLUME [/app/lib]
VOLUME [/app/config]

ENV DLC="${DLC}"

ENV PATH="${DLC}:${DLC}/bin:${JAVA_HOME}/bin:${PATH}"
RUN chown openedge:openedge /usr/dlc/progress.cfg && \
    /app/pas/as/bin/oeprop.sh AppServer.SessMgr.agentStartupParam="-T \"\${catalina.base}/temp\" -pf /app/config/as.pf" && \
    rm /usr/dlc/progress.cfg

ENV PASWEBHANDLERS=/app/src/webhandlers/ROOT.handlers

WORKDIR /app/pas

LABEL maintainer="Ruben Dröge <rdroge@progress.com>"

CMD ["/app/pas/start.sh"]