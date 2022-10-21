FROM rwdroge/openedge_pas_orads:12.6

USER root

ENV LD_LIBRARY_PATH=/opt/oracle/client/lib
ENV ORACLE_HOME=/opt/oracle/client

ADD ./binaries/Pro2-6.4.0.bin response.properties /install/pro2/

WORKDIR /install/pro2

RUN ./Pro2-6.4.0.bin -i Silent -f response.properties && \  
    chown -R openedge:openedge /install/pro2 -R && \
    rm -rf Pro2-6.4.0.bin

WORKDIR /install/pro2/bprepl/Scripts

COPY replProc.pf sports2020.pf ./ 
COPY schemaholder/* /install/pro2/db
COPY start.sh /install/pro2/start.sh 
CMD ["/install/pro2/start.sh"]

EXPOSE 9991 9992