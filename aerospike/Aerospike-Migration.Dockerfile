FROM aerospike/aerospike-tools:latest

# script to orchestrate the automatic namespace creation and apply all migration scripts
ADD aerospike/scripts/autoMigrate.sh /usr/local/bin/autoMigrate
RUN chmod 755 /usr/local/bin/autoMigrate

# script to run any aql script from src/main/resources/config/aql
ADD aerospike/scripts/execute-aql.sh  /usr/local/bin/execute-aql
RUN chmod 755 /usr/local/bin/execute-aql

ENTRYPOINT ["autoMigrate"]
