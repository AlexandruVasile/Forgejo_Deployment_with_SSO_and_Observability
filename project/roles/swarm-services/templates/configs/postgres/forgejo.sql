-- TODO
-- TODO
CREATE DATABASE {{ POSTGRES_FORGEJO_DB }};
CREATE USER {{ POSTGRES_FORGEJO_USER }} WITH PASSWORD '{{ POSTGRES_FORGEJO_PASSWORD }}';
GRANT ALL PRIVILEGES ON DATABASE {{ POSTGRES_FORGEJO_DB }} TO {{ POSTGRES_FORGEJO_USER }};
\connect {{ POSTGRES_FORGEJO_DB }} {{ POSTGRES_ADMIN_USER }};
GRANT ALL ON SCHEMA {{ POSTGRES_FORGEJO_SCHEMA }} TO {{ POSTGRES_FORGEJO_USER }};
