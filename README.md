# App templates

Open source applications template

```
root@frappehr-l2xps-u21607:~# docker ps
CONTAINER ID   IMAGE                           COMMAND                  CREATED          STATUS                   PORTS                        NAMES
ceaa84e8682c   elestio/nginx-auto-ssl:latest   "/entrypoint.sh /usr…"   5 minutes ago    Up 5 minutes                                          elestio-nginx
361707bc4b67   elestio/phpmyadmin              "/docker-entrypoint.…"   8 minutes ago    Up 7 minutes             172.17.0.1:40749->80/tcp     app-pma-1
095056ae04da   elestio/erpnext:latest          "bench worker --queu…"   8 minutes ago    Up 7 minutes                                          app-queue-short-1
63783630b091   elestio/erpnext:latest          "node /home/frappe/f…"   8 minutes ago    Up 7 minutes                                          app-websocket-1
a17844fe22bd   elestio/erpnext:latest          "bench worker --queu…"   8 minutes ago    Up 7 minutes                                          app-queue-long-1
e7e4a76beeda   elestio/redis:6.2               "docker-entrypoint.s…"   8 minutes ago    Up 8 minutes             6379/tcp                     app-redis-queue-1
3df02d5d36e6   elestio/erpnext:latest          "/home/frappe/frappe…"   8 minutes ago    Up 8 minutes                                          app-backend-1
5c4c9109566d   elestio/mariadb:10.6            "docker-entrypoint.s…"   8 minutes ago    Up 8 minutes (healthy)   3306/tcp                     app-db-1
a5754d30748d   elestio/redis:6.2               "docker-entrypoint.s…"   8 minutes ago    Up 8 minutes             6379/tcp                     app-redis-cache-1
03fd1f04febe   elestio/erpnext:latest          "bench schedule"         8 minutes ago    Up 7 minutes                                          app-scheduler-1
93ea007f378c   elestio/redis:6.2               "docker-entrypoint.s…"   8 minutes ago    Up 8 minutes             6379/tcp                     app-redis-socketio-1
30aae1d1ef98   elestio/erpnext:latest          "bench worker --queu…"   8 minutes ago    Up 7 minutes                                          app-queue-default-1
08ce9bef5a90   elestio/erpnext:latest          "nginx-entrypoint.sh"    8 minutes ago    Up 8 minutes             172.17.0.1:32755->8080/tcp   app-frontend-1
18bb8afbb424   boky/postfix                    "/bin/sh -c /scripts…"   10 minutes ago   Up 10 minutes            172.17.0.1:25->587/tcp       elestio-postfix
root@frappehr-l2xps-u21607:~#
```
