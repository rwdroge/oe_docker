FROM ubuntu:24.04 as install

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
FROM ubuntu:24.04 as instance

RUN groupadd -g 1000 openedge && \
    useradd -m -r -u 1000 -g openedge openedge

#RUN apt-get update && \
#    apt install nodejs && \
#    apt install npm

    # apt-get install -y dotnet-sdk-8.0 && \
    # dotnet new console -n test && \
    # dotnet new sln -n test && \
    # dotnet sln test.sln add test/test.csproj && \
    # chown openedge:openedge -R /test

# WORKDIR /test
   
# RUN dotnet add package MathNet.Numerics --version 5.0.0

ENV JAVA_HOME=/opt/java/openjdk
ENV DLC=/usr/dlc
ENV WRKDIR=/usr/wrk
ENV TERM=xterm

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

RUN mkdir -p /app/src && mkdir /artifacts && \
    chown -R openedge:openedge /app /artifacts

USER openedge

WORKDIR /app/src

LABEL maintainer="Ruben Dröge <rdroge@progress.com>"

ENV PATH="${DLC}:${DLC}/bin:${JAVA_HOME}/bin:${PATH}"