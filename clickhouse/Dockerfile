# ClickHouse 25.3 (the floor for Future AGI's v2 spans schema) with upstream's
# config files: the `tiered` storage policy, small-host settings and the
# default user's password from CLICKHOUSE_PASSWORD.
FROM clickhouse/clickhouse-server:25.3.14.14-alpine@sha256:a4e8cf46e526a06f4f52d22f7fa8d07472b55d3c896d7ca3f159e249be38ae62
ENV CLICKHOUSE_SKIP_USER_SETUP=1 \
    CLICKHOUSE_DB=default
COPY config.d/ /etc/clickhouse-server/config.d/
COPY users.d/ /etc/clickhouse-server/users.d/
EXPOSE 8123 9000
