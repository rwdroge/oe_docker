# oe_demos_docker

## Pro2Oracle Docker Demo Environment
### Prerequisites:
-	Docker installed
    -	Docker Desktop for Windows
    -	WSL2 (Windows Subsystem for Linux)
    -	Or: Linux VM with Docker installed
-	Docker-Compose installed

### Containers:
-	Sports2020 DB
-	Repl DB
-	Pro2 DB
-	Oracle DB
-	Pro2 (PASOE)

Job runner is started by default and replication is setup for sports2020 source database to the Oracle database. Pro2 properties have been imported already.
One mapping is defined for the Benefits table, but no CDC-mapping has been done yet for that table and code hasn’t been generated either.
Setup Environment:
-	Clone repository (https://github.com/rwdroge/oe_demos_docker)
-	Navigate to Pro2 folder
-	CMD > docker-compose up

### Demo Script:
-	Show dashboard and explain what people are looking at and then move to ‘Manage Replication’
-	Show the generation of the target schema (‘Generate Target Schema’)
    - Explain the Job scheduler (background process that picks up all scheduled jobs)
    - Show the various generated SQL-scripts
-	Add a mapping next to the existing mapping for the Benefits table
    -	Maybe only select certain fields to replicate
-	Add CDC Mappings for these mappings as well
-	[Optional] Assign Benefits / Other table that has been mapped to different replication threads under the ‘Advanced Configuration’ menu item
-	Generate Code
    -	[Optional]: show generated code in brepl/repl_mproc (bulkload) and brepl/repl_proc (replication) using an interactive Docker session into the pas_pro2 container:
      
      ```docker exec -it <container_id> /bin/sh```
    
      ```ls /install/pro2/bprepl/repl_mproc```
    
      ```ls /install/pro2/bprepl/repl_proc```

-	Go to [Actions > Jobs > Scheduled Jobs]
-	Select the job of type ‘CDC Threads’ and choose ‘Run Now’
    -	This starts the CDC administration thread that captures changes in the CDC tables

-	Select one of the jobs of type ‘Replication Threads’ and choose ‘Run Now’
    -	This starts 1 or all of the replication threads and will replicate the actual changes from source to target
-	Go to [Actions > Bulk Load > Run Bulk Loads]
    -	Select the source database (sports2020)
    -	Select ‘Yes’ for ‘Reload table if already bulk-loaded once’
    - Choose ‘Run’ and confirm that the bulk load has executed successfully by running the Bulk Load Report via [Actions > Bulk Load > Bulk Load Report
    -	Explain that the bulk load needs to run initially as a starting point (after that only changes are replicated incrementally)
