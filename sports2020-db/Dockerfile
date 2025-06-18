FROM progressofficial/oe_db_adv:12.8.7 AS install

COPY schema/* /app/schema/
COPY schema/ /app/db/   
USER openedge

VOLUME /app/db
VOLUME /app/schema

WORKDIR /app/db

CMD [ "bash", "-c", "/app/scripts/startdb.sh" ]
#CMD [ "tail", "-f",  "/dev/null" ]