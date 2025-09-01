FROM ubuntu:24.04 AS install

ARG CTYPE

ENV JAVA_HOME=/opt/java/openjdk
COPY --from=eclipse-temurin:JDKVERSION $JAVA_HOME $JAVA_HOME
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# the running process (i.e. the github action) is responsible for placing the install .tar 
# in the correct location
ADD installer/PROGRESS_OE.tar.gz /install/openedge/
ADD installer/PROGRESS_PATCH_OE.tar.gz /install/patch/
ADD scripts/install-oe.sh /install/

COPY db_adv/response.ini /install/openedge/response.ini
ENV TERM=linux

COPY scripts/clean-oe-files.sh /install/openedge/clean-oe-files.sh 
RUN /install/install-oe.sh && \
    cat /install/install_oe.log && \
    /install/openedge/clean-oe-files.sh ${CTYPE} && \
    rm -f /usr/dlc/progress.cfg && \
    rm -rf /install 

# multi stage build, this give the possibilty to remove all the slack from stage 0
FROM ubuntu:24.04 AS instance

LABEL maintainer="Ruben Dröge <rdroge@progress.com>"

ENV JAVA_HOME=/opt/java/openjdk
ENV DLC=/usr/dlc
ENV WRKDIR=/usr/wrk
ENV TERM=linux
COPY --from=install $JAVA_HOME $JAVA_HOME
COPY --from=install $DLC $DLC
COPY --from=install $WRKDIR $WRKDIR

COPY db_adv/protocols /etc/
COPY db_adv/services /etc/
RUN chmod 644 /etc/protocols && \
    chmod 644 /etc/services

WORKDIR /usr/dlc/bin

RUN chown root _* && \
    chmod 4755 _* && \
    chmod 755 _sql* && \
    chmod -f 755 _waitfor || true

ENV PATH=$DLC:$DLC/bin:$PATH:${JAVA_HOME}/bin:${PATH}

RUN groupadd -g 980 openedge && \
    useradd -r -u 980 -g openedge openedge

# allow for progress.cfg to be copied into $DLC
# kubernetes does not support volume mount of single files
RUN chown root:openedge $DLC && \
    chmod 775 $DLC && \
    touch /usr/dlc/progress.cfg && \
    chown openedge:openedge /usr/dlc/progress.cfg

# create directories and files as root
COPY db_adv/scripts/* /app/scripts/
COPY db_adv/conf/* /app/db/
COPY scripts/* /app/scripts/
RUN mkdir -p /app/backup /app/config /app/data /app/db /app/schema /app/scripts /app/tmp && \
    chmod +x /app/scripts/*.sh && \
    chown -R openedge:openedge /app/ 

USER openedge

VOLUME /app/db
VOLUME /app/schema
VOLUME /app/data

WORKDIR /app/db

CMD [ "bash", "-c", "/app/scripts/startdb.sh" ]