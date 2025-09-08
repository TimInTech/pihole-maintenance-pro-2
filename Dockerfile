# Sidecar-Image, das das Wartungsskript mit optionalem Cron ausführt
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash curl ca-certificates jq coreutils procps iputils-ping mailutils \
      tzdata logrotate cron sqlite3 \
      docker.io \
 && rm -rf /var/lib/apt/lists/*

# Verzeichnisse
RUN mkdir -p /usr/local/bin /etc/pihole-maintenance-pro /var/log/pihole-maintenance-pro /var/backups/pihole

# Skripte hinein kopieren
COPY src/pihole_maintenance_pro.sh /usr/local/bin/pihole_maintenance_pro.sh
COPY src/runner.sh /usr/local/bin/runner.sh
COPY config.example /etc/pihole-maintenance-pro/config.cfg

RUN chmod 0755 /usr/local/bin/pihole_maintenance_pro.sh /usr/local/bin/runner.sh \
 && ln -sf /usr/local/bin/pihole_maintenance_pro.sh /usr/local/bin/pmp

# Standard: Simple Runner mit Intervall (CRON_SCHEDULE optional)
ENV CRON_SCHEDULE=""

# Docker Socket optional für docker exec in Pi-hole Container
VOLUME ["/var/run/docker.sock", "/var/log/pihole-maintenance-pro", "/var/backups/pihole", "/etc/pihole-maintenance-pro"]

HEALTHCHECK --interval=5m --timeout=30s --retries=3 CMD /usr/local/bin/pihole_maintenance_pro.sh --health || exit 1

ENTRYPOINT ["/usr/local/bin/runner.sh"]
