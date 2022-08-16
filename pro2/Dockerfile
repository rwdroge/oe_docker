FROM rwdroge/openedge_pas_orads:12.5.2

USER root

RUN apk add --no-cache bash && \
    ldconfig /opt/oracle/client/lib

ENV LD_LIBRARY_PATH /opt/oracle/client/lib:$LD_LIBRARY_PATH
ENV ORACLE_HOME /opt/oracle/client

ADD Pro2-6.3.0.bin response.properties /install/pro2/

WORKDIR /install/pro2

RUN ./Pro2-6.3.0.bin -i Silent -f response.properties && \  
    chown -R openedge:openedge /install/pro2 -R && \
    rm -rf Pro2-6.3.0.bin

USER openedge

WORKDIR /install/pro2/bprepl/Scripts

COPY replProc.pf sports2020.pf ./ 
COPY schemaholder/* /install/pro2/db
COPY start.sh /install/pro2/start.sh 

RUN /install/pro2/Pro2Web/bin/oeprop.sh +AppServer.SessMgr.Pro2Web.agentStartupParam="-T ../temp -pf /install/pro2/bprepl/Scripts/replProc.pf" 

CMD ["/install/pro2/start.sh"]

EXPOSE 9991 9992