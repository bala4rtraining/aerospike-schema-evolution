##### Aerospike schema evolution
The changelog folder for aerospike/cql files is similar to Liquibase (for SQL databases), but with a minimal tooling.
Many thanks to jHipster team, general idea comes from them.

##### Script structure requirements
- The script name should follow the pattern yyyyMMddHHmmss_{script-name}.aql
  - eg: 20150805124838_added_entity_BankAccount.aql
- The scripts will be applied sequentially in alphabetical order

##### Warning notes
- The scripts should be applied automatically only in two contexts:
  - Unit tests
  - Docker-compose for local development
- Scripts should not be automatically applied to the database when deployed with a production profile
- To achieve this save approach there should be customization in dockerfile entry point, as by default it is much more convenient to have automigrate as entry point

##### Environment variables
AEROSPIKE_SCHEMA_VERSION_NAMESPACE <- namespace that will have schema_version set

##### Production run notes
With default automigrate, ensure database backup before triggering this run

##### Simple work check
1. From root project directory. This will create aerospike db container and from another container will run migration scripts for database
```bash
docker-compose up
```
2. From root project directory. Visual check that scrips are being applied  
```bash
docker exec -it aerospike aql
show sets
select * from auto-migrate-test.schema_version
select * from auto-migrate-test.test_users
```
