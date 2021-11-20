#!/bin/bash
set -euxo pipefail

loki_ip_address="${1:-10.11.12.2}"

# see https://github.com/grafana/loki/releases
# see https://hub.docker.com/r/grafana/promtail/tags
loki_version="2.4.1"

# destroy the existing promtail container and data.
docker rm --force promtail && rm -rf ~/promtail && mkdir ~/promtail

cd ~/promtail

# configure promtail.
# see https://grafana.com/docs/loki/latest/clients/promtail/configuration/#example-journal-config
# see https://grafana.com/docs/loki/latest/clients/promtail/scraping/#journal-scraping-linux-only
sed -E "s,@@loki_push_url@@,http://$loki_ip_address:3100/loki/api/v1/push,g" /vagrant/promtail-config.yml \
    >config.yml

# start promtail.
docker run \
    -d \
    --restart unless-stopped \
    --name promtail \
    -v /var/log/journal/:/var/log/journal/ \
    -v /run/log/journal/:/run/log/journal/ \
    -v /etc/machine-id:/etc/machine-id \
    -v "$PWD:/var/run/promtail" \
    grafana/promtail:$loki_version \
        -config.file=/var/run/promtail/config.yml
