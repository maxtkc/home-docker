FROM traefik:v3.0

# Copy static configuration
COPY traefik.yml /etc/traefik/traefik.yml

# Copy dynamic configuration files
COPY dynamic/ /etc/traefik/dynamic/

# Ensure proper permissions
RUN chmod -R 644 /etc/traefik/