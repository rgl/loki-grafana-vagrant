#!/bin/bash
set -euxo pipefail

loki_ip_address="${1:-10.11.12.2}"

# install the loki docker log driver plugin.
# see https://grafana.com/docs/loki/latest/clients/docker-driver/configuration/
docker plugin \
    install \
    grafana/loki-docker-driver:2.2.1 \
    --alias loki \
    --grant-all-permissions
docker plugin ls

# reconfigure docker to use the loki log-driver.
# see https://grafana.com/docs/loki/latest/clients/docker-driver/configuration/
log_opts="$(jo \
labels='worker_id' \
loki-url="http://$loki_ip_address:3100/loki/api/v1/push"  \
loki-external-labels='container_name={{.Name}},container_id={{.ID}}' \
loki-relabel-config="\
- regex: filename
  action: labeldrop
"
)"
jq 'del(."log-driver") | del(."log-opts") | ."log-driver" = $log_driver | ."log-opts" = $log_opts' \
    --arg log_driver loki \
    --argjson log_opts "$log_opts" \
    /etc/docker/daemon.json \
    | sponge /etc/docker/daemon.json
systemctl restart docker

# leave an example running.
docker run \
    -d \
    --restart unless-stopped \
    --name date-ticker \
    --label worker_id=test \
    debian:buster-slim \
    bash -c 'while true; do date; sleep 15; done'
