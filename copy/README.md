# Copy

Copy new open source application `docker-compose.yml` and other config files. And make them compatible for OctaByte

# Steps

1. Create folder with new application name
2. Copy `docker-compose.yml` file in folder
3. Convert `.env` file into `env.txt`
4. Go to `/opt/app` and copy scripts if any
5. Copy `name.yml` and convert into `web.txt` if any, other wise get detail from email
6. Add Traefik to `docker-compose.yml`
7. Add `APP_URL=$SERVICE_DOMAIN` in `env.txt`

## Script file

`https://api.elest.io/api/servers/getCloudInit?token=9BpKvmz0-JSdh-GOFniWtl`

## Ghost-241030

`https://elestio-monitoring-backend-prod.vm.openvm.cloud/server.html?serverToken=ckgCq59P-mWMu-SYB6vuqY`
