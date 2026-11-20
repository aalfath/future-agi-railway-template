# PostgreSQL 16 (Debian/glibc, as upstream's docker-compose.yml uses) with
# upstream's small-host settings. Data lives in a subfolder of the volume.
FROM postgres:16.16@sha256:3950ad7c3148ca2175ef1b6c36c9efbf78957ae8fbe8b3a5d7c35af50500382f
ENV PGDATA=/var/lib/postgresql/data/pgdata \
    POSTGRES_USER=futureagi \
    POSTGRES_DB=futureagi
CMD ["postgres", "-c", "max_connections=200", "-c", "shared_buffers=64MB", \
     "-c", "effective_cache_size=256MB", "-c", "work_mem=4MB", \
     "-c", "maintenance_work_mem=32MB", "-c", "wal_buffers=4MB", \
     "-c", "max_wal_size=512MB", "-c", "min_wal_size=64MB", \
     "-c", "wal_level=logical", "-c", "max_replication_slots=25", \
     "-c", "listen_addresses=*"]
