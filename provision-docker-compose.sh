#!/bin/bash
set -euxo pipefail

docker_compose_version="${1:-1.29.2}"; shift || true

# download.
# see https://github.com/docker/compose/releases
# see https://docs.docker.com/compose/install/#install-compose-on-linux-systems
docker_compose_url="https://github.com/docker/compose/releases/download/$docker_compose_version/docker-compose-$(uname -s)-$(uname -m)"
wget -qO /tmp/docker-compose "$docker_compose_url"

# install.
install -o root -g root -m 555 /tmp/docker-compose /usr/local/bin
rm /tmp/docker-compose
docker-compose --version
