FROM rdroge/openedge_pas_orads:12.8.3

USER root

ADD ./binaries/Pro2-6.5.1.bin response.properties /install/pro2/

WORKDIR /install/pro2

RUN ./Pro2-6.5.1.bin -i Silent -f response.properties && \  
    chown -R pscadmin:pscadmin /install/pro2 -R && \
    rm -rf Pro2-6.5.1.bin

WORKDIR /install/pro2/bprepl/Scripts

ENV LD_LIBRARY_PATH=/opt/oracle/client/lib
ENV ORACLE_HOME=/opt/oracle/client

COPY replProc.pf sports2020.pf ./ 
COPY schemaholder/* /install/pro2/db
COPY start.sh /install/pro2/start.sh 

USER root

CMD ["/install/pro2/start.sh"]

EXPOSE 9991 9992