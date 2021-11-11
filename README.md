# CKAN on Docker
This repository provides CKAN environment on Docker. This environment contains these containers.

- CKAN
- Datapusher
- PostGIS
- Solr
- Redis
- Minio

## How to run CKAN

```bash
$ cp .env.example .env
$ docker compose pull
$ docker compose build
$ docker compose up -d
$ docker compose logs -f ckan  # wait for starting ckan process then exit with ctrl + c
$ docker compose exec ckan ckan -c /etc/ckan/default/ckan.ini datastore set-permissions | docker compose exec postgis psql -U ckan
$ docker compose exec ckan ckan -c /etc/ckan/default/ckan.ini sysadmin add ${USER_NAME}
```
