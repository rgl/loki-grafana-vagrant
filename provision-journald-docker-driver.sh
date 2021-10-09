#!/bin/bash
set -euxo pipefail

loki_ip_address="${1:-10.11.12.2}"

# reconfigure docker to use the journald log-driver.
# NB promtail is also configured to process the containers logs.
#    see the promtail-config.yml file.
# see https://docs.docker.com/config/containers/logging/journald/
# see https://docs.docker.com/config/containers/logging/configure/
python3 <<'EOF'
import json

with open('/etc/docker/daemon.json', 'r') as f:
    config = json.load(f)

config['log-driver'] = 'journald'
config['log-opts'] = {
    'labels': 'workflow_id',
}

with open('/etc/docker/daemon.json', 'w') as f:
    json.dump(config, f, indent=4)
EOF
systemctl restart docker

# leave an example running.
docker run \
    -d \
    --restart unless-stopped \
    --name date-ticker \
    --label workflow_id=test-workflow-id \
    alpine:3.14 \
        sh -c 'while true; do date; sleep 15; done'
