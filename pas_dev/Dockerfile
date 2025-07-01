FROM ubuntu:22.04 as install

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

COPY pas_dev/response.ini /install/openedge/response.ini
ENV TERM xterm

RUN /install/install-oe.sh

RUN cat /install/install_oe.log
# RUN /usr/dlc/bin/proDebugEnable -enable-all

RUN rm /usr/dlc/progress.cfg

COPY scripts/clean-oe-files.sh /install/openedge/clean-oe-files.sh 
# This script needs 'container type' as input parameter as it differs what folders can be removed
RUN /install/openedge/clean-oe-files.sh ${CTYPE}

# multi stage build, this give the possibilty to remove all the slack from stage 0
FROM ubuntu:22.04 as instance
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    net-tools \
  # && apt-get install -y dotnet-runtime-8.0 \
  && apt-get install -y dotnet-sdk-8.0 \
  && apt install netbase \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd -g 1000 openedge \
  && useradd -r -u 1000 -g openedge openedge
  
RUN dotnet new console -n test && \
    dotnet new sln -n test && \
    dotnet sln test.sln add test/test.csproj
   
RUN dotnet add package MathNet.Numerics --version 5.0.0 && \
    ls
  
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

WORKDIR /usr/dlc/bin

RUN chown root _* && \
    chmod 4755 _* && \
    chown root:openedge $DLC $WRKDIR && \
    chmod 775 $DLC && \
    chmod 777 $WRKDIR && \
    touch /usr/dlc/progress.cfg  && \
    chown openedge:openedge /usr/dlc/progress.cfg && \
    mkdir -p /app/pas &&     mkdir /app/src &&     mkdir /app/lib &&     mkdir /app/config && \
    chown -R openedge:openedge /app      

WORKDIR /app/pas

# what happens if I create the PAS with the actual openedge user? File permissions ok?
RUN pasman create -p 8810 -P 8811 -j 8812 -s 8812 -Z dev -f -N pas -U openedge -G openedge ./as 

WORKDIR /app/pas/as

RUN bin/oeprop.sh AppServer.Agent.pas.PROPATH=".,/app/config,/app/src,/app/lib/logic.pl,/app/dep1,/app/dep2,/app/dep3,/app/dep4,/app/dep5,\${DLC}/tty,\${DLC}/tty/OpenEdge.Core.pl,\${DLC}/tty/netlib/OpenEdge.Net.pl" &&     touch /app/pas/as.pf &&     bin/oeprop.sh AppServer.SessMgr.agentStartupParam="-T \"\${catalina.base}/temp\" -pf ./../../as.pf" &&     bin/oeprop.sh AppServer.SessMgr.pas.agentLogFile="\${catalina.base}/logs/pas.agent.log" && \
    mkdir -p /app/pas/as/webapps/ROOT/WEB-INF/adapters/web/ROOT/ && \
    chown -R openedge:openedge /app/pas/as

COPY pas_dev/config/oeablSecurity-dev.csv /app/pas/as/webapps/ROOT/WEB-INF/oeablSecurity.csv
COPY pas_dev/start.sh /app/pas/
RUN chmod +x /app/pas/start.sh && \
    chown -R openedge:openedge /app/pas/start.sh && \
    echo 'tcp    6 TCP' >> /etc/protocols

VOLUME /app/src
VOLUME /app/lib
VOLUME /app/config

ENV DLC="${DLC}"

RUN chown openedge:openedge /usr/dlc/progress.cfg && \
    /app/pas/as/bin/oeprop.sh AppServer.SessMgr.agentStartupParam="-T \"\${catalina.base}/temp\" -pf /app/config/as.pf" && \
    rm /usr/dlc/progress.cfg

ENV PASWEBHANDLERS=/app/src/webhandlers/ROOT.handlers
USER openedge

WORKDIR /app/pas

LABEL maintainer="Ruben Dröge <rdroge@progress.com>"

CMD ["/app/pas/start.sh"]