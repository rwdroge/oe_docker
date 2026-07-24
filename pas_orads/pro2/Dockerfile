ARG BASE_IMAGE
FROM ${BASE_IMAGE}

LABEL maintainer="Ruben Dröge <rdroge@progress.com>"

USER root

COPY ./binaries/Pro2-6.5.2.bin ./response.properties /install/pro2/

WORKDIR /install/pro2

ENV JAVA_TOOL_OPTIONS='-Djdk.util.zip.disableZip64ExtraFieldValidation=true'

# Create progress.cfg file to avoid Pro2 installer ESAM error 
RUN touch /usr/dlc/progress.cfg && \
    chmod +x Pro2-6.5.2.bin && \
    ./Pro2-6.5.2.bin -i Silent -f response.properties && \
    rm -rf Pro2-6.5.2.bin

# Pro2 installer creates the PASOE instance, so we don't need to do it manually
WORKDIR /home/openedge/install/pro2/bprepl/Scripts

# Copy Oracle TNS configuration (LD_LIBRARY_PATH and ORACLE_HOME already set in base image)
COPY tnsnames.ora /opt/oracle/client/network/admin/tnsnames.ora

# Copy Pro2 configuration files
COPY replProc.pf sports2020.pf ./ 
COPY schemaholder/* /home/openedge/install/pro2/db/
COPY start.sh /install/pro2/start.sh 

# Set permissions and cleanup
RUN chmod +x /install/pro2/start.sh && \
    chown -R openedge:openedge /home/openedge/ && \
    rm /usr/dlc/progress.cfg

VOLUME /usr/dlc/progress.cfg

EXPOSE 9991 9992

USER openedge

CMD ["/install/pro2/start.sh"]