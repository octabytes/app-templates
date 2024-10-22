set env vars
set -o allexport; source .env; set +o allexport;

mkdir -p ./docker
chown -R 1000:1000 ./docker

mkdir -p ./superset_home
chown -R 1000:1000 ./superset_home

mkdir -p ./redis
chown -R 1000:1000 ./redis

mkdir -p ./db_home
chown -R 1000:1000 ./db_home

chmod +x ./docker
chmod +x ./docker/*.sh


cat << EOF > ./docker/pythonpath_dev/superset_config_docker.py
SECRET_KEY = '${ADMIN_PASSWORD}'
EMAIL_NOTIFICATIONS = False
WTF_CSRF_ENABLED = False
SUPERSET_WEBSERVER_PROTOCOL = 'https'
APP_NAME = 'Superset'
EOF


sed -i "s~--password ~--password ${ADMIN_PASSWORD}~g" ./docker/docker-init.sh
sed -i "s~--email ~--email ${ADMIN_EMAIL}~g" ./docker/docker-init.sh
