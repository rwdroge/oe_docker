FROM jenkins/agent:latest-jdk17 as builder
ARG user=jenkins

USER root

ENV DOCKERVERSION=19.03.12
LABEL Description="This image is derived from jenkins/agent openjdk17."

RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz \
  && tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 \
                 -C /usr/local/bin docker/docker \
  && rm docker-${DOCKERVERSION}.tgz
WORKDIR /home/${user}

RUN mkdir /installer
COPY ./response.ini /installer/
WORKDIR /installer
ADD ./binaries/PROGRESS_OE_12.8.3_LNX_64.tar.gz ./


WORKDIR /etc
RUN /installer/proinst -b /installer/response.ini -l ./install.log
RUN cat ./install.log

# cleanup stuff we do not need for runtime
RUN rm -rf /usr/oemgmt/ \
    /usr/wrk_oemgmt/ \
    /usr/dlc/demo* \
    /usr/dlc/empty* \
    /usr/dlc/esbadapter/ \
    /usr/dlc/hello \
    /usr/dlc/inst_hlp \
    /usr/dlc/javahelp/ \
    /usr/dlc/newkw* \
    /usr/dlc/notice.txt \
    /usr/dlc/odbc/ \
    /usr/dlc/oebuild/ \
    /usr/dlc/ora/ \
    /usr/dlc/prohelp/ \
    /usr/dlc/prolang/ \
    /usr/dlc/servers/ \
    /usr/dlc/sonic/ \
    /usr/dlc/templates/ \
    /usr/dlc/ubqmanager/

# fix permissions
RUN find /usr/dlc -type d -exec chmod 'o-w' '{}' ';' &&\
    find /usr/dlc -type f -exec chmod 'o-rwx' '{}' ';' 

# -------------- FINAL IMAGE -------------
# Now create final container as small as possible
# FROM eclipse-temurin:11.0.13_8-jdk-focal

# copy /psc from the builder instance to this one
# COPY --from=builder /psc /psc
# we need to enable TCP 
# RUN echo 'tcp    6 TCP' >> /etc/protocols

ENV PATH=/usr/dlc:/usr/dlc/bin:/usr/dlc/ant/bin:$PATH \
    WRKDIR=/usr/wrk/ \
    DLC=/usr/dlc/

LABEL maintainer="rdroge@progress.com"

COPY ./start.sh /installer 
COPY ./binaries/OpenEdge.BusinessLogic.pl /usr/dlc/src/OpenEdge.BusinessLogic.pl

USER root

CMD [ "/installer/start.sh" ]
