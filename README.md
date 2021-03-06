# About

This is an example [loki](https://github.com/grafana/loki) vagrant environment.

The `loki` machine:

* Hosts loki.
* Hosts Grafana.
* Configures promtail to send the journal to `loki`.

The `ubuntu1` machine:

* Configures loki docker driver to send the container logs to `loki`.
* Configures promtail to send the journal to `loki`.

The `ubuntu2` machine:

* Configures docker to send the container logs to the journal.
* Configures promtail to send the journal to `loki`.

## Usage

Start the `loki` machine:

```bash
time vagrant up --provider=libvirt --no-destroy-on-error --no-tty loki
```

Start the loki client machines:

```bash
time vagrant up --provider=libvirt --no-destroy-on-error --no-tty ubuntu1 ubuntu2
```

Explore the logs with Grafana:

http://10.11.12.2:3000/explore

Explore the logs with logcli:

```bash
vagrant ssh loki

# list all series/streams.
logcli series '{}' | sort

# list all series/streams from the ubuntu1 host.
logcli series '{host="ubuntu1"}' | sort

# list all labels.
logcli labels -q | sort

# list all sources.
logcli labels -q source | sort

# get all the systemd-journal logs.
logcli query '{job="systemd-journal"}'

# get all the docker service logs.
logcli query '{job="systemd-journal",source="docker.service"}'

# get all the docker plugins logs.
logcli query '{job="systemd-journal",source="docker.service"} |~ " plugin="'

# tail all the container logs.
logcli query --tail '{job="container"}'

# tail the date-ticker container logs.
logcli query --tail '{job="container",source="date-ticker"}'

# raw tail the date-ticker container logs.
logcli query --tail --output raw '{job="container",source="date-ticker"}'
```

## Alternatives

* [vector](https://vector.dev/) ([timberio/vector](https://github.com/timberio/vector))
  * https://github.com/grafana/loki/issues/2361#issuecomment-826732810

## References

* Loki:
  * https://github.com/grafana/loki
  * https://grafana.com/docs/loki/latest/logql/
  * https://grafana.com/docs/loki/latest/getting-started/logcli/
  * https://grafana.com/docs/loki/latest/configuration/examples/#complete-local-config
  * https://grafana.com/docs/loki/latest/installation/docker/
* Loki Docker Driver:
  * [Configuring the Docker Driver](https://grafana.com/docs/loki/latest/clients/docker-driver/configuration/)
* Journald Docker Driver:
  * [Journal Scraping (Linux Only)](https://grafana.com/docs/loki/latest/clients/promtail/scraping/#journal-scraping-linux-only)
  * [Journald logging driver](https://docs.docker.com/config/containers/logging/journald/)
  * [Configure logging drivers](https://docs.docker.com/config/containers/logging/configure/)
* Grafana:
  * https://grafana.com/docs/grafana/latest/administration/configure-docker/
  * https://grafana.com/docs/grafana/latest/administration/provisioning/#datasources
  * https://grafana.com/docs/grafana/latest/datasources/loki/#configure-the-data-source-with-provisioning
* systemd journal:
  * https://www.freedesktop.org/software/systemd/man/systemd.journal-fields.html#Trusted%20Journal%20Fields
    * You can use `journalctl -n 1 -o json | jq .` to see an actual journal log message (including metadata).
