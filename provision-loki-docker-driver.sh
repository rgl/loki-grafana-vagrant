#!/bin/bash
set -euxo pipefail

loki_ip_address="${1:-10.11.12.2}"

# install the loki docker log driver plugin.
# see https://grafana.com/docs/loki/latest/clients/docker-driver/configuration/
# see https://hub.docker.com/r/grafana/loki-docker-driver
# see https://github.com/grafana/loki/tree/main/clients/cmd/docker-driver
docker plugin install \
    --alias loki \
    --grant-all-permissions \
    grafana/loki-docker-driver:2.2.1 \
        LOG_LEVEL=debug
docker plugin ls

# reconfigure docker to use the loki log-driver.
# see https://grafana.com/docs/loki/latest/clients/docker-driver/configuration/
python3 <<EOF
import json

loki_relabel_config = '''\
# drop filename, we have no use for it.
- regex: filename
  action: labeldrop
'''

loki_pipeline_stages = '''\
'''

# NB loki-relabel-config is executed once per container.
# NB loki-pipeline-stages is executed once per container log line.
# NB the filename label is set once per container.
# NB the source label is set per container log line.
log_opts = {
    'labels': 'worker_id',
    'loki-url': 'http://$loki_ip_address:3100/loki/api/v1/push',
    'loki-external-labels': 'job=container,container_name={{.Name}}',
    'loki-relabel-config': loki_relabel_config,
    'loki-pipeline-stages': loki_pipeline_stages,
    'max-size': '10m',
    'max-file': '3',
}

with open('/etc/docker/daemon.json', 'r') as f:
    config = json.load(f)

config['log-driver'] = 'loki'
config['log-opts'] = log_opts

with open('/etc/docker/daemon.json', 'w') as f:
    json.dump(config, f, indent=4)
EOF
systemctl restart docker

# leave an example running.
docker run \
    -d \
    --restart unless-stopped \
    --name date-ticker \
    --label worker_id=test \
    debian:buster-slim \
    bash -c 'while true; do date; sleep 15; done'
