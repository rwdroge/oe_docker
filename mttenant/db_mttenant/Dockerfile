FROM eclipse-temurin:17.0.3_7-jdk-centos7 AS builder-jdk

FROM progresssoftware/prgs-oedb:12.6.0_adv-ent
USER root
# Needs a valid license file for building the container image (creating the db)
COPY --chown=pscadmin:pscadmin ./conf/progress.cfg /psc/dlc/progress.cfg

ARG JDK_DOCKER_IMAGE_JAVA_LOCATION=/opt/java/openjdk
COPY --from=builder-jdk --chown=pscadmin:pscadmin ${JDK_DOCKER_IMAGE_JAVA_LOCATION} /usr/java

COPY --chown=pscadmin:pscadmin ./artifacts /deploy/artifacts/
COPY --chown=pscadmin:pscadmin ./abl-triggers /deploy/abl-triggers/
COPY --chown=pscadmin:pscadmin ./conf /deploy/scripts/config/
COPY --chown=pscadmin:pscadmin ./hook-script.sh /deploy/scripts/
COPY --chown=pscadmin:pscadmin ./scripts /deploy/scripts/
COPY --chown=pscadmin:pscadmin ./conf/startup.pf /deploy/scripts/config/

RUN chmod +x /deploy/scripts -R
USER pscadmin

ARG DB_CREATE_METHOD=backupDB
ARG DB_NAME=mttenant
ARG EXTERNAL_DATABASE_PATH=/psc/wrk/mttenant

ENV DB_CREATE_METHOD=${DB_CREATE_METHOD} \
    DB_NAME=${DB_NAME} \
    EXTERNAL_DATABASE_PATH=${EXTERNAL_DATABASE_PATH} \
    LD_LIBRARY_PATH=/usr/java/jre/lib/amd64/server/:/usr/java/jre/lib/amd64/:/usr/java/lib/server

# creates the relevant OpenEdge Database


RUN /deploy/scripts/create-db.sh
RUN /deploy/scripts/hook-script.sh
# Remove the license file before our internal license is out there
RUN rm /psc/dlc/progress.cfg

CMD ["/bin/sh", "-c", "/deploy/scripts/start-db-server.sh"]
