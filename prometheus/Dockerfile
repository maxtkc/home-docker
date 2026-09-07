FROM prom/prometheus:latest

# Copy configuration
COPY prometheus.yml /etc/prometheus/prometheus.yml
COPY alerts.yml /etc/prometheus/alerts.yml

USER nobody