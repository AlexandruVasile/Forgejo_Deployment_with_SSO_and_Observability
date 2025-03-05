FROM grafana/grafana-oss:10.2.2
USER root

# TODO install entrypoint dependencies
RUN apk add --no-cache curl jq postgresql-client ca-certificates
# TODO install entrypoint
COPY entrypoint.sh /entrypoint
RUN chmod +x /entrypoint

# TODO invoke our entrypoint
USER 1000
ENTRYPOINT [ "/entrypoint" ]