FROM alpine:3.19
RUN apk add --no-cache curl jq

COPY entrypoint.sh /entrypoint
RUN chmod +x /entrypoint
ENTRYPOINT [ "/entrypoint" ]
