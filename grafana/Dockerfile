FROM grafana/grafana:latest

# Copy provisioning files into the container
COPY provisioning/ /etc/grafana/provisioning/
COPY dashboards/ /var/lib/grafana/dashboards/

# Set ownership for Grafana user
USER root
RUN chown -R 472:472 /etc/grafana/provisioning/ /var/lib/grafana/dashboards/
USER 472