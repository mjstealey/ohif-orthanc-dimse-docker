#!/usr/bin/env bash
set -e

# until [ $(pg_isready -h postgres -q)$? -eq 0 ]; do
#   >&2 echo "Postgres is unavailable - sleeping"
#   sleep 1
# done

sleep 20s
>&2 echo "Postgres is up - continuing"

cat > /tmp/postgres.json <<EOF
  "PostgreSQL" : {
    "EnableIndex" : true,
    "EnableStorage" : true,
    "Host" : "postgres",
    "Port" : ${POSTGRES_PORT},
    "Database" : "${POSTGRES_DB}",
    "Username" : "${POSTGRES_USER}",
    "Password" : "${POSTGRES_PASSWORD}"
  },
EOF

sed -i '/"Name" :.*/r /tmp/postgres.json' /etc/orthanc/orthanc.json
cat /etc/orthanc/orthanc.json
sleep 1s

exec Orthanc /etc/orthanc/
