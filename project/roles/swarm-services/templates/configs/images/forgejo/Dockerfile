FROM codeberg.org/forgejo/forgejo:1.21
# TODO install entrypoint dependencies

# maybe curl is already there
RUN apk add --no-cache curl jq sudo postgresql-client ca-certificates





# TODO install and use new entrypoint
COPY entrypoint.sh /entrypoint
RUN chmod +x /entrypoint
ENTRYPOINT [ "/entrypoint" ]
