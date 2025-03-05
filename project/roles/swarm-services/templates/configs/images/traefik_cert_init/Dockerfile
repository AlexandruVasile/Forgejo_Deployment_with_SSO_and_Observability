FROM alpine:3.19.0

RUN apk update && \
  apk add --no-cache openssl && \
  rm -rf "/var/cache/apk/*"

ADD entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
