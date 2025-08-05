FROM rdroge/openedge_pas_orads:12.8.3

USER root

ADD ./binaries/Pro2-6.5.2.bin response.properties /install/pro2/

WORKDIR /install/pro2

RUN chmod +x Pro2-6.5.2.bin && \
    export JAVA_TOOL_OPTIONS='-Djdk.util.zip.disableZip64ExtraFieldValidation=true' && \
    sh ./Pro2-6.5.2.bin LAX_VM "/opt/java/openjdk/bin/java" -i Silent -f response.properties && \
    chown -R pscadmin:pscadmin /install/pro2 -R && \
    rm -rf Pro2-6.5.2.bin

WORKDIR /install/pro2/bprepl/Scripts
RUN apt-get update && \
    apt-get install libaio1

ENV LD_LIBRARY_PATH=/opt/oracle/client/lib
ENV ORACLE_HOME=/opt/oracle/client
RUN ldconfig /opt/oracle/client/lib
COPY replProc.pf sports2020.pf ./ 
COPY tnsnames.ora /opt/oracle/client/network/admin/tnsnames.ora
COPY schemaholder/* /install/pro2/db
COPY start.sh /install/pro2/start.sh 
RUN chmod +x /install/pro2/start.sh

USER root

CMD ["/install/pro2/start.sh"]

EXPOSE 9991 9992