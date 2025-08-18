FROM progressofficial/oe_db_adv:latest AS install

COPY schema/* /app/schema/
COPY schema/ /app/db/   
COPY data/* /app/data/ 
USER openedge

VOLUME /app/db
VOLUME /app/schema

WORKDIR /app/db

CMD [ "bash", "-c", "/app/scripts/startdb.sh" ]
