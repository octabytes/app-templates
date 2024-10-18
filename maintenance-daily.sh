echo "$(tail -c 30m /tmp/appStack.log)" > /tmp/appStack.log
echo "$(tail -c 30m /var/log/syslog)" > /var/log/syslog
journalctl --vacuum-time=10d --vacuum-size=500M;