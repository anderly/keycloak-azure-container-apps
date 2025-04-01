# Use the official Keycloak image as base
FROM quay.io/keycloak/keycloak:26.1.4 as builder

# Enable health and metrics support
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

WORKDIR /opt/keycloak

RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:26.1.4
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Configure database
# ENV KC_DB=postgres
# ENV KC_DB_URL=jdbc:postgresql://postgres:5432/keycloak
# ENV KC_DB_USERNAME=postgres
# ENV KC_DB_PASSWORD=postgres

# Configure ports
#ENV KC_HOSTNAME=localhost
ENV KC_PROXY=edge
ENV KC_HTTP_PORT=8443
ENV KC_HTTP_ENABLED=true
ENV KC_HOSTNAME_PORT=8443
ENV KC_HOSTNAME_STRICT_BACKCHANNEL=false
ENV KC_PROXY-HEADERS=xforwarded
ENV KC_HOSTNAME-STRICT=false
ENV KC_HOSTNAME_STRICT_HTTPS=false

# Configure admin user
#ENV KEYCLOAK_ADMIN=admin
#ENV KEYCLOAK_ADMIN_PASSWORD=admin
#ENV KC_BOOTSTRAP_ADMIN_USERNAME="admin"
#ENV KC_BOOTSTRAP_ADMIN_PASSWORD="admin"

# Copy custom themes if needed
COPY themes/ /opt/keycloak/themes/

# Copy custom realms if needed
COPY realms/ /opt/keycloak/data/import/

# Copy custom providers if needed
COPY providers/ /opt/keycloak/providers/

# Copy custom configuration if needed
COPY conf/ /opt/keycloak/conf/

EXPOSE 8443

# Start Keycloak in production mode
ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start", "--import-realm"]