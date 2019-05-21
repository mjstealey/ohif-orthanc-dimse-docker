# OHIF Viewer - Orthanc with DIMSE - Nginx reverse proxy

Docker Compose implementation of OHIF Viewer using Orthanc with DIMSE and Nginx reverse proxy

- OHIF Viewer: [ohif/viewer:latest](https://hub.docker.com/r/ohif/viewer)
- MongoDB: [mongo:latest](https://hub.docker.com/_/mongo)
- Orthanc: [jodogne/orthanc-plugins:latest](https://hub.docker.com/r/jodogne/orthanc-plugins)
- PostgreSQL 11: [postgres:11](https://hub.docker.com/_/postgres)
- Nginx: [nginx:latest](https://hub.docker.com/_/nginx/)

This work is intended to be a complete working example of a docker based deployment demonstrating the OHIF Viewer using Orthanc as the image store served using Nginx and self signed SSL certificates. This work should not be considered production as presented, but rather a sane starting point for further implementation of security related features.

- Orthanc docker containers as described at [http://book.orthanc-server.com/users/docker.html](http://book.orthanc-server.com/users/docker.html)
- OHIF Viewer docker containers as described at [https://github.com/OHIF/Viewers](https://github.com/OHIF/Viewers)
- Sample DICOM images downloaded from [https://www.dicomlibrary.com](https://www.dicomlibrary.com)

## TL;DR

Run the services defined in docker-compose.yml and daemonize them.

```
docker-compose up -d
```

Once completed you should see five containers running

```console
$ docker-compose ps
  Name                Command              State                      Ports
----------------------------------------------------------------------------------------------
mongo      docker-entrypoint.sh mongod     Up      27017/tcp
nginx      nginx -g daemon off;            Up      0.0.0.0:8443->443/tcp, 0.0.0.0:8080->80/tcp
orthanc    Orthanc /etc/orthanc/           Up      4242/tcp, 8042/tcp
postgres   docker-entrypoint.sh postgres   Up      5432/tcp
viewer     pm2-runtime app.json            Up      3000/tcp
```
Wait a few moments for the setup scripts to run and go to [https://127.0.0.1:8443/](https://127.0.0.1:8443/) (You may be prompted to manually accept the SSL certificate because it is self signed)

We've not loaded any study images yet, so you should simply see the OHIF Viewer with **No matching results** being displayed.

<img width="80%" alt="OHIF Viewer - initial" src="https://user-images.githubusercontent.com/5332509/58113815-659b6500-7bc4-11e9-9746-18573b9ed988.png">

Next, navigate to [https://127.0.0.1:8443/orthanc](https://127.0.0.1:8443/orthanc) and Sign in

- Username: **orthanc**
- Password: **orthanc**

Once signed in, load the sample data from the `dicom-samples` directory (Upload tab)

<img width="80%" alt="Orthanc - select files" src="https://user-images.githubusercontent.com/5332509/58114399-a9429e80-7bc5-11e9-887f-930077cb0e76.png">

Go to [https://127.0.0.1:8443/studylist](https://127.0.0.1:8443/studylist) and double click on the loaded study

<img width="80%" alt="OHIF Viewer - interact with study" src="https://user-images.githubusercontent.com/5332509/58115596-6e8e3580-7bc8-11e9-8fa6-38fb233d20a2.png">

Enjoy!

**DEPLOYMENT NOTE**

Presently the **orthanc** container does not have any graceful checks for when the **postgres** container is ready to accept connections, so it can potentially fail and restart (along with the nginx container) prior to gaining a successful connection. It would be preferable to start the **postgres** container first, and then start the **orthanc** container once PostgreSQL is ready.

Start the postgres and mongo containers, and wait for postgres to finish it's setup (Look for **_database system is ready to accept connections_** when looking at the output of `docker-compose logs postgres`)

```
docker-compose up -d postgres mongo
```

Once the **postgres** container has finished it's setup, then start **nginx**, **orthanc** and **viewer** containers

```
docker-compose up -d nginx orthanc viewer
```

## Configuration and Usage

### Update `.env` file

The `.env` file defines the Nginx, OHIF Viewer, MongoDB, Orthanc and PostgreSQL parameters that will be used by the Docker containers running your services. The default values are shown below.

```bash
# Nginx configuration
NGINX_DEFAULT_CONF=./nginx/default.conf
NGINX_SSL_CERT=./ssl/ssl_dev.crt
NGINX_SSL_KEY=./ssl/ssl_dev.key

# OHIF Viewer
VIEWER_CONFIG=./config/viewer.json

# MongoDB
MONGO_DATA_MNT=./mongo_data
MONGO_PORT=27017
MONGO_URL=mongodb://mongo:27017/ohif

# Orthanc core with plugins
ORTHANC_CONFIG=./config/orthanc.json
ORTHANC_DB_MNT=./orthanc_db
ORTHANC_DICOM_PORT=4242
ORTHANC_HTTP_PORT=8042

# PostgreSQL database - default values should not be used in production
PGDATA=/var/lib/postgresql/data
POSTGRES_DB=orthanc
POSTGRES_DATA_MNT=./pg_data/data
POSTGRES_PASSWORD=pgpassword
POSTGRES_PORT=5432
POSTGRES_USER=postgres
```

**NOTE**: The default configuration files for Orthanc and OHIF Viewer are in the [config/](config) directory. It is left to the user to update these for their own use. Links to supporting documentation can be found in the References section.

### Run the compose services

Run the services defined in docker-compose.yml and daemonize them. You'll notice that only the `http` and `https` ports have been left exposed to the host. The values for other container ports have been left in the docker-compose.yml file for reference, but have been commented out.

Port defaults for provided example:

- HTTP: `8080` (Nginx config will redirect to the HTTPS port)
- HTTPS: `8443`

The **postgres** and **mongo** containers should be started first

```
docker-compose up -d postgres mongo
```

You should notice two containers running on the host.

```console
$ docker-compose ps
  Name                Command              State     Ports
------------------------------------------------------------
mongo      docker-entrypoint.sh mongod     Up      27017/tcp
postgres   docker-entrypoint.sh postgres   Up      5432/tcp
```

It will take a few moments for the **postgres** container to complete it's start up scripts, but when completed the container logs should look similar to this:

```console
$ docker-compose logs postgres
...
postgres    |
postgres    | PostgreSQL init process complete; ready for start up.
postgres    |
postgres    | 2019-05-21 16:26:58.469 UTC [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
postgres    | 2019-05-21 16:26:58.470 UTC [1] LOG:  listening on IPv6 address "::", port 5432
postgres    | 2019-05-21 16:26:58.473 UTC [1] LOG:  listening on Unix socket "/var/run/postgresql/.s.PGSQL.5432"
postgres    | 2019-05-21 16:26:58.561 UTC [62] LOG:  database system was shut down at 2019-05-21 16:26:58 UTC
postgres    | 2019-05-21 16:26:58.594 UTC [1] LOG:  database system is ready to accept connections
```

Next start the **nginx**, **orthanc** and **viewer** containers

```
docker-compose up -d nginx orthanc viewer
```

Once completed you should see five containers running

```console
$ docker-compose ps
  Name                Command              State                      Ports
----------------------------------------------------------------------------------------------
mongo      docker-entrypoint.sh mongod     Up      27017/tcp
nginx      nginx -g daemon off;            Up      0.0.0.0:8443->443/tcp, 0.0.0.0:8080->80/tcp
orthanc    Orthanc /etc/orthanc/           Up      4242/tcp, 8042/tcp
postgres   docker-entrypoint.sh postgres   Up      5432/tcp
viewer     pm2-runtime app.json            Up      3000/tcp
```

### Validate OHIF Viewer in browser

If using the default configuration as defined above, the Studylist will be available at: [https://127.0.0.1:8443/studylist](https://127.0.0.1:8443/studylist) (You may be prompted to manually accept the SSL certificate because it is self signed)

<img width="80%" alt="OHIF Viewer - initial" src="https://user-images.githubusercontent.com/5332509/58113815-659b6500-7bc4-11e9-9746-18573b9ed988.png">

We've not loaded any study images yet, so you should simply see the OHIF Viewer with **No matching results** being displayed.

### Validate Orthanc in browser

Next, navigate to [https://127.0.0.1:8443/orthanc](https://127.0.0.1:8443/orthanc) and Sign in

- Username: **orthanc**
- Password: **orthanc**

<img width="80%" alt="Orthanc - login" src="https://user-images.githubusercontent.com/5332509/58114070-f8d49a80-7bc4-11e9-95f8-975f9f23cd04.png">

Once signed in the explorer page should be presented

<img width="80%" alt="Orthanc - initial" src="https://user-images.githubusercontent.com/5332509/58114118-1275e200-7bc5-11e9-8bd3-ad8103d9acd5.png">

### Load DICOM study images in Orthanc

A small set of DICOM sample images have been included in the repository for testing purposes.

Click the Upload link in the upper right corner and select files to upload from the [dicom-samples/](dicom-samples) directory.

<img width="80%" alt="Orthanc - select files" src="https://user-images.githubusercontent.com/5332509/58114399-a9429e80-7bc5-11e9-887f-930077cb0e76.png">

Start the upload

<img width="80%" alt="Orthanc - upload files" src="https://user-images.githubusercontent.com/5332509/58114634-2c63f480-7bc6-11e9-8424-c063709c466f.png">

From the Orthanc home page, select "All studies", and the uploaded files should be available as **Anonymized - CT1 abdomen**

<img width="80%" alt="Orthanc - all studies" src="https://user-images.githubusercontent.com/5332509/58114776-7c42bb80-7bc6-11e9-81d6-d4acb2a08a4f.png">

Click the study and use the tools to interact with the loaded files

<img width="80%" alt="Orthanc - select study" src="https://user-images.githubusercontent.com/5332509/58114819-97153000-7bc6-11e9-896f-ff0fea405e88.png">

### Work with loaded images in OHIF Viewer

Going back to the OHIF Viewer you should observe the Anonymized study we loaded from Orthanc as an option to interact with: [https://127.0.0.1:8443/studylist](https://127.0.0.1:8443/studylist)

<img width="80%" alt="OHIF Viewer - anon study" src="https://user-images.githubusercontent.com/5332509/58115493-2cfd8a80-7bc8-11e9-9738-41dc71cf23ac.png">

Double click on the Anonymized study to load and interact with it

<img width="80%" alt="OHIF Viewer - interact with study" src="https://user-images.githubusercontent.com/5332509/58115596-6e8e3580-7bc8-11e9-8fa6-38fb233d20a2.png">


## Clean up

```
docker-compose stop && docker-compose rm -f
docker volume prune -f
docker network prune -f
rm -rf mongo_data orthanc_db pg_data
```

## References

- Othanc: [http://book.orthanc-server.com/index.html](http://book.orthanc-server.com/index.html)
- OHIF Viewer: [https://docs.ohif.org](https://docs.ohif.org)
- DICOM Library: [https://www.dicomlibrary.com](https://www.dicomlibrary.com)
- Nginx reverse proxy: [https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
