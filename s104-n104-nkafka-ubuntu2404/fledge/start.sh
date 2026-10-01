#!/bin/bash
set -euo pipefail

# Unprivileged Docker containers do not have access to the kernel log. This prevents an error when starting rsyslogd.
sed -i '/imklog/s/^/#/' /etc/rsyslog.conf

# Ubuntu 24.04 minimal does not have any service manager, start rsyslogd by calling the binary
rsyslogd

/usr/local/fledge/bin/fledge -u admin -p fledge start
for _ in {1..60}; do
    curl -fsS http://localhost:8081/fledge/ping >/dev/null && break
    sleep 1
done
curl -fsS http://localhost:8081/fledge/ping >/dev/null

password_token=$(curl -fsS -X POST http://localhost:8081/fledge/login \
    -H 'content-type: application/json' \
    -d '{"username":"admin","password":"fledge"}' | jq -er '.token')
if [[ -n "$password_token" ]]; then
    curl -fsS -X PUT http://localhost:8081/fledge/category/rest_api \
        -d '{"authentication":"optional"}' -H "authorization: $password_token" >/dev/null
fi

sleep 2
/bin/bash /usr/local/fledge/importModules.sh "$password_token"
tail -f /var/log/syslog
