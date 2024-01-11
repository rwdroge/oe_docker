FROM rdroge/openedge_pas_base:12.7.0

USER openedge

WORKDIR /app/pas
ADD start.sh /app/pas

# create pasoe production instance and activate healthcheck feature
RUN pasman create -p 8220 -P 8221 -s 8222 -v prodpas && \
    /app/pas/prodpas/bin/tcman.sh feature HealthCheck=on
    
EXPOSE 8220 8221 8899