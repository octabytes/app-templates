journalctl --vacuum-time=10d --vacuum-size=500M;
/opt/renew-vm-cert.sh;
cd /opt/elestio/nginx && docker-compose down;
cd /opt/elestio/nginx && docker-compose up -d;
docker image prune -a -f
