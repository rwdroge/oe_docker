FROM rwdroge/openedge_pas_instance:12.6

USER openedge 

COPY rcode/ /app/pas/prodpas/openedge 
COPY webhandlers/mttenantHandler.r /app/pas/prodpas/webapps/ROOT/WEB-INF/openedge/mttenantHandler.r
COPY conf/startup.pf /app/pas/prodpas/conf 
COPY conf/ABLDomainRegistry.keystore /app/pas/prodpas/conf
COPY conf/oeablSecurity.properties /app/pas/prodpas/conf/merge.properties
COPY conf/OEUserRealm.properties /app/pas/prodpas/openedge

RUN /app/pas/prodpas/bin/oeprop.sh +AppServer.allowRuntimeUpdates=1 \
    /app/pas/prodpas/bin/oeprop.sh +AppServer.SessMgr.prodpas.agentStartupParam="-T ../temp -pf ../conf/startup.pf" \
    /app/pas/prodpas/bin/oeprop.sh +AppServer.SessMgr.prodpas.agentLoggingLevel=2 \
    /app/pas/prodpas/bin/oeprop.sh +AppServer.Agent.prodpas.agentShutdownProc= \
    /app/pas/prodpas/bin/oeprop.sh +AppServer.Agent.prodpas.agentStartupProc=startup/as_authstartup.p \
    /app/pas/prodpas/bin/oeprop.sh +AppServer.Agent.prodpas.agentStartupProcParam= \
    /app/pas/prodpas/bin/oeprop.sh +AppServer.Agent.prodpas.numInitialSessions=2 \
    /app/pas/prodpas/bin/oeprop.sh +AppServer.Agent.prodpas.sessionActivateProc=startup/activate.p \
    /app/pas/prodpas/bin/oeprop.sh +AppServer.Agent.prodpas.sessionConnectProc= \
    /app/pas/prodpas/bin/oeprop.sh +AppServer.Agent.prodpas.sessionDeactivateProc= \
    /app/pas/prodpas/bin/oeprop.sh +AppServer.Agent.prodpas.sessionDisconnProc= \
    /app/pas/prodpas/bin/oeprop.sh +AppServer.Agent.prodpas.sessionShutdownProc= \
    /app/pas/prodpas/bin/oeprop.sh +AppServer.Agent.prodpas.sessionStartupProc= \
    /app/pas/prodpas/bin/oeprop.sh +AppServer.Agent.prodpas.sessionStartupProcParam= \
    /app/pas/prodpas/bin/oeprop.sh +AppServer.Agent.prodpas.updateProperties=false \
    /app/pas/prodpas/bin/oeprop.sh "+AppServer.Agent.prodpas.PROPATH=../webapps/ROOT/WEB-INF/openedge,../openedge,${DLC}/tty,${DLC}/tty/netlib/OpenEdge.Net.pl," \
    /app/pas/prodpas/bin/oeprop.sh +prodpas.ROOT.allowRuntimeUpdates=1 \
    /app/pas/prodpas/bin/oeprop.sh +prodpas.ROOT.SOAP.adapterEnabled=0 \
    /app/pas/prodpas/bin/oeprop.sh +prodpas.ROOT.statusEnabled=1 \
    /app/pas/prodpas/bin/oeprop.sh +prodpas.ROOT.WEB.adapterEnabled=1 \
    /app/pas/prodpas/bin/oeprop.sh +prodpas.ROOT.APSV.adapterEnabled=0 \
    /app/pas/prodpas/bin/oeprop.sh +prodpas.ROOT.WEB.defaultHandler=OpenEdge.Web.CompatibilityHandler \
    /app/pas/prodpas/bin/oeprop.sh "+prodpas.ROOT.WEB.handler1=mttenantHandler: /api/{apitype}/{entityname}/{id1}/{entityname2}/{id2}" \
    /app/pas/prodpas/bin/oeprop.sh "+prodpas.ROOT.WEB.handler2=mttenantHandler: /api/{apitype}/{entityname}/{id1}/{entityname2}" \
    /app/pas/prodpas/bin/oeprop.sh "+prodpas.ROOT.WEB.handler3=mttenantHandler: /api/{apitype}/{entityname}/{id1}" \
    /app/pas/prodpas/bin/oeprop.sh "+prodpas.ROOT.WEB.handler4=mttenantHandler: /api/{apitype}/{entityname}" 

RUN /usr/dlc/bin/secprop -f -w prodpas.prodpas.ROOT /app/pas/prodpas/conf/merge.properties

CMD ["/app/pas/start.sh"]

