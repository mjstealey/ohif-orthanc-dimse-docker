# Orthanc in Docker with PostgreSQL

Docker Compose implementation of the [jodogne/orthanc-plugins:latest](https://hub.docker.com/r/jodogne/orthanc-plugins) and [postgres:11](https://hub.docker.com/_/postgres) docker containers as described at [http://book.orthanc-server.com/users/docker.html](http://book.orthanc-server.com/users/docker.html).

## Usage

### Update `.env` file

Update the .env file that docker-compose.yml will use to define the PostgreSQL and Orthanc parameters

```env
# PostgreSQL database - default values should not be used in production
PGDATA=/var/lib/postgresql/data
POSTGRES_DB=orthanc
POSTGRES_PASSWORD=pgpassword
POSTGRES_PORT=5432
POSTGRES_USER=postgres

# Orthanc core with plugins
ORTHANC_DICOM_PORT=4242
ORTHANC_HTTP_PORT=8042
```

### Update `docker-compose.yml` file

Update the docker-compose.yml file to appropriaty map the volume mounts for PostgreSQL database data and Orthanc data. Defaults are present working directory from where the compose file is invoked.

```docker-compose
...
  postgres:
...
    volumes:
      - ./pg_data/data:${PGDATA:-/var/lib/postgresql/data}
      - ./pg_data/logs:${POSTGRES_INITDB_WALDIR:-/var/log/postgresql}
...
  orthanc:
...
    volumes:
      - ./orthanc-db:/var/lib/orthanc/db
...
```

### Run the compose services

Run the services defined in docker-compose.yml and daemonize them.

```
docker-compose up -d
```

You should notice two containers running on the host.

```console
$ docker-compose ps
  Name                Command              State                       Ports
-------------------------------------------------------------------------------------------------
orthanc    /docker-entrypoint.sh           Up      0.0.0.0:4242->4242/tcp, 0.0.0.0:8042->8042/tcp
postgres   docker-entrypoint.sh postgres   Up      0.0.0.0:5432->5432/tcp
```

It will take a few moments for the `orthanc` container to complete it's start up scripts, but when completed the container logs should look similar to this:

```console
...
orthanc     | W0424 15:07:31.925776 PluginsManager.cpp:168] Clearing the cache of the Web viewer
orthanc     | W0424 15:07:31.930110 PluginsManager.cpp:168] Web viewer using a cache of 100 MB
orthanc     | W0424 15:07:31.930159 PluginsManager.cpp:168] Using GDCM instead of the DICOM decoder that is built in Orthanc
orthanc     | W0424 15:07:31.930789 PluginsManager.cpp:269] Registering plugin 'wsi' (version mainline)
orthanc     | W0424 15:07:31.931034 PluginsManager.cpp:168] The whole-slide imaging plugin will use at most 4 threads to transcode the tiles
orthanc     | W0424 15:07:31.931741 PluginsManager.cpp:269] Registering plugin 'postgresql-index' (version mainline)
orthanc     | W0424 15:07:31.932179 main.cpp:1224] Using a custom database from plugins
orthanc     | W0424 15:07:31.932224 main.cpp:1235] Using a custom storage area from plugins
orthanc     | W0424 15:07:32.341265 PluginsManager.cpp:168] Trying to enable trigram matching on the PostgreSQL database to speed up wildcard searches. This may take several minutes
orthanc     | W0424 15:07:32.421550 PluginsManager.cpp:168] Trigram index has been created
orthanc     | W0424 15:07:32.500199 HttpClient.cpp:744] HTTPS will use the CA certificates from this file: /etc/orthanc/
orthanc     | W0424 15:07:32.501409 LuaContext.cpp:103] Lua says: Lua toolbox installed
orthanc     | W0424 15:07:32.501825 LuaContext.cpp:103] Lua says: Lua toolbox installed
orthanc     | W0424 15:07:32.502192 ServerContext.cpp:316] Disk compression is disabled
orthanc     | W0424 15:07:32.502265 ServerIndex.cpp:1613] No limit on the number of stored patients
orthanc     | W0424 15:07:32.503269 ServerIndex.cpp:1630] No limit on the size of the storage area
orthanc     | W0424 15:07:32.505496 JobsEngine.cpp:283] The jobs engine has started with 2 threads
orthanc     | W0424 15:07:32.506172 main.cpp:932] DICOM server listening with AET ORTHANC on port: 4242
orthanc     | W0424 15:07:32.506236 HttpServer.cpp:1155] HTTP compression is enabled
orthanc     | W0424 15:07:32.509634 HttpServer.cpp:1062] HTTP server listening on port: 8042 (HTTPS encryption is disabled, remote access is allowed)
orthanc     | W0424 15:07:32.509688 main.cpp:712] Orthanc has started
```

At this point the **orthanc** database of the `postgres` container should also have the required tables as defined by Orthanc.

```console
$ docker exec -u postgres postgres psql -d orthanc -c '\dt;'
                 List of relations
 Schema |         Name          | Type  |  Owner
--------+-----------------------+-------+----------
 public | attachedfiles         | table | postgres
 public | changes               | table | postgres
 public | deletedfiles          | table | postgres
 public | deletedresources      | table | postgres
 public | dicomidentifiers      | table | postgres
 public | exportedresources     | table | postgres
 public | globalintegers        | table | postgres
 public | globalproperties      | table | postgres
 public | maindicomtags         | table | postgres
 public | metadata              | table | postgres
 public | patientrecyclingorder | table | postgres
 public | remainingancestor     | table | postgres
 public | resources             | table | postgres
 public | storagearea           | table | postgres
(14 rows)
```

### Validate in browser

If using the default configuration as defined above, the Sign-In screen will be available at: [http://localhost:8042/]()

- username: **orthanc**
- password: **orthanc**

<img width="80%" alt="login screen" src="docs/imgs/orthanc-login.png">

Once signed in the explorer page should be presented:

<img width="80%" alt="home page" src="docs/imgs/orthanc-home.png">


