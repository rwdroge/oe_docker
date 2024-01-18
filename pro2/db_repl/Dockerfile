ARG OE_VERSION

FROM adoptopenjdk/openjdk11:latest AS builder-jdk

FROM progresssoftware/prgs-oedb:$OE_VERSION"_adv-ent"
USER pscadmin

COPY --chown=pscadmin:pscadmin ./conf/progress.cfg /psc/dlc/progress.cfg

ARG JDK_DOCKER_IMAGE_JAVA_LOCATION=/opt/java/openjdk
COPY --from=builder-jdk --chown=pscadmin:pscadmin ${JDK_DOCKER_IMAGE_JAVA_LOCATION} /usr/java/ 
COPY --chown=pscadmin:pscadmin ./artifacts /deploy/artifacts/ 
#COPY --chown=pscadmin:pscadmin ./abl-triggers /deploy/abl-triggers/ 
COPY --chown=pscadmin:pscadmin ./conf /deploy/scripts/config/ 
COPY --chown=pscadmin:pscadmin ./scripts /deploy/scripts/ 
     
RUN chmod +x /deploy/scripts -R
ARG DB_CREATE_METHOD=externalDB
ARG DB_NAME=repl
ARG EXTERNAL_DATABASE_PATH=/psc/wrk/repl

ENV DB_CREATE_METHOD=${DB_CREATE_METHOD} \
    DB_NAME=${DB_NAME} \
    EXTERNAL_DATABASE_PATH=${EXTERNAL_DATABASE_PATH} \
    LD_LIBRARY_PATH=/usr/java/jre/lib/amd64/server/:/usr/java/jre/lib/amd64/:/usr/java/lib/server

# creates the relevant OpenEdge Database
RUN /deploy/scripts/create-db.sh && \   
    /deploy/scripts/hook-script.sh 

USER root

RUN chown pscadmin:pscadmin /psc/wrk/repl -R

USER pscadmin         

RUN rm /psc/dlc/progress.cfg

CMD ["/bin/sh", "-c", "/deploy/scripts/start-db-server.sh"]
