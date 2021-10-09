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
    grafana/loki-docker-driver:2.3.0 \
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
# always use the host hostname as the host that generated the container logs.
- target_label: host
  replacement: '$(hostname)'
'''

loki_pipeline_stages = '''\
# rename container_name to source.
- labels:
    source: container_name
- labeldrop:
    - container_name
'''

# NB loki-relabel-config is executed once per container.
# NB loki-pipeline-stages is executed once per container log line.
# NB the filename label is set once per container.
# NB the source label is set per container log line.
# NB its not possible to get a label from the docker daemon itself.
#    see https://github.com/grafana/loki/issues/3847
log_opts = {
    'labels': 'workflow_id',
    'loki-url': 'http://$loki_ip_address:3100/loki/api/v1/push',
    'loki-external-labels': 'job=container,worker_id=test-worker-id,container_name={{.Name}}',
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

# docker plugins are running as containerd containers in the plugins.moby namespace.
ctr --namespace plugins.moby containers ls
ctr --namespace plugins.moby tasks ls

# leave an example running.
docker run \
    -d \
    --restart unless-stopped \
    --name date-ticker \
    --label workflow_id=test-workflow-id \
    alpine:3.14 \
        sh -c 'while true; do date; sleep 15; done'
