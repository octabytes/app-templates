docker run -d --restart always --no-healthcheck --name elestio-postfix -e RELAYHOST=internal-smtp-proxy.elestio.app:24 -e POSTFIX_smtpd_tls_security_level=none -e RELAYHOST_USERNAME=test.vm.octabyte.io@vm.elestio.app -e RELAYHOST_PASSWORD=DFDOTH3s-VsuW-q4Bcg3g9 -e ALLOWED_SENDER_DOMAINS=vm.elestio.app -p 172.17.0.1:25:587 -e POSTFIX_myhostname=test.vm.octabyte.io boky/postfix
