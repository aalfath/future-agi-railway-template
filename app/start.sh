#!/usr/bin/env bash
# Railway wrapper for futureagi/standalone. Maps the template's variables
# (private hosts of the Postgres, ClickHouse and Serving services, generated
# secrets, the public domain) onto the settings upstream's docker-compose.yml
# passes, writes the edge proxy config, then runs upstream's entrypoint.
set -euo pipefail

if [ "$#" -gt 0 ]; then
  exec /opt/futureagi/bin/start "$@"
fi

need() { if [ -z "${!1:-}" ]; then echo "[railway] $1 is not set; check the service variables" >&2; exit 1; fi; }
for v in PG_HOST PG_PASSWORD CH_HOST SECRET_KEY REDIS_PASSWORD MINIO_ROOT_PASSWORD \
         AGENTCC_INTERNAL_API_KEY AGENTCC_ADMIN_TOKEN INTEGRATION_ENCRYPTION_KEY \
         PROPERTY_CATALOG_CH_PASSWORD PROPERTY_CATALOG_CONSUMER_PASSWORD; do
  need "$v"
done

# --- public URLs: one Railway domain serves the UI, API, traces, gateway, files
PUBLIC_URL="${FUTURE_AGI_PUBLIC_URL:-}"
if [ -z "$PUBLIC_URL" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then PUBLIC_URL="https://${RAILWAY_PUBLIC_DOMAIN}"; fi
PUBLIC_URL="${PUBLIC_URL:-http://localhost:${PORT:-8090}}"
PUBLIC_URL="${PUBLIC_URL%/}"
PUBLIC_HOST="${PUBLIC_URL#*://}"
export APP_URL="${APP_URL:-$PUBLIC_HOST}"
export BASE_URL="${BASE_URL:-$PUBLIC_URL}"
export FRONTEND_URL="${FRONTEND_URL:-$PUBLIC_URL}"
export VITE_HOST_API="${VITE_HOST_API:-$PUBLIC_URL}"
export MINIO_URL="${MINIO_URL:-$PUBLIC_URL}"
export FI_COLLECTOR_PUBLIC_URL="${FI_COLLECTOR_PUBLIC_URL:-$PUBLIC_URL}"
export AGENTCC_GATEWAY_PUBLIC_URL="${AGENTCC_GATEWAY_PUBLIC_URL:-$PUBLIC_URL/gateway}"
export HARNESS_PUBLIC_BASE_URL="${HARNESS_PUBLIC_BASE_URL:-}"

# --- fixed settings from upstream docker-compose.yml (v1.59.1), app service
d() { export "$1=${!1:-$2}"; }
d ENV_TYPE local; d DEBUG false; d DJANGO_SETTINGS_MODULE tfc.settings.settings
export NO_STARTUP_DB_MUTATIONS=true FI_SKIP_CH25_MIGRATION=1
d FI_CDC_MODE outbox; d OTEL_ENABLED false
d FUTURE_AGI_VERSION v1.59.1; d FUTURE_AGI_DEPLOYMENT_TYPE docker
d FUTURE_AGI_TELEMETRY_DISABLED false; d FUTURE_AGI_TELEMETRY_JITTER_SECONDS 1800
d FUTURE_AGI_TELEMETRY_BUFFER_DIR /data/telemetry; d FUTURE_AGI_TELEMETRY_URL https://api.futureagi.com
d FUTURE_AGI_TELEMETRY_INTERVAL_HOURS 6; d FUTURE_AGI_TELEMETRY_TIMEOUT_SECONDS 5
d GRANIAN_THREADS 2; export ENABLE_GRPC=false
d EXACT_AGGREGATION_TASK_QUEUE exact_aggregation; d TEMPORAL_EXCLUDED_QUEUES simulation_runner
d TEMPORAL_MAX_CONCURRENT_ACTIVITIES 8; d TEMPORAL_MAX_CONCURRENT_WORKFLOW_TASKS 8
export TEMPORAL_GRACEFUL_SHUTDOWN_TIMEOUT=30; d REDIS_MAXMEMORY 128mb
export TEMPORAL_HOST=127.0.0.1:7233 TEMPORAL_NAMESPACE=default
export REDIS_HOST=127.0.0.1 REDIS_PORT=6379
R="redis://:${REDIS_PASSWORD}@127.0.0.1:6379"
export REDIS_URL="$R/0" REDIS_CACHE_URL="$R/1" REDIS_LOCK_URL="$R/2" REDIS_STATE_URL="$R/2" \
       CHANNEL_LAYER_BACKEND=redis CHANNEL_REDIS_URL="$R/3"
export WEBSOCKET_ENDPOINT=http://127.0.0.1:8000/call-websocket/
export AGENTCC_INTERNAL_URL=http://127.0.0.1:8080 AGENTCC_GATEWAY_INTERNAL_URL=http://127.0.0.1:8080
d ALK_RUNNER_API_URL http://127.0.0.1:8000
# Code evals run in the app's built-in Python sandbox (the nsjail executor
# needs privileged containers, which Railway doesn't run).
export CODE_EXECUTOR_URL=http://127.0.0.1:8060 CODE_EXECUTOR_LOCAL_FALLBACK=false COMPOSE_PROFILES=
d MODEL_SERVING_URL ""
export FI_COLLECTOR_HOST=127.0.0.1 FI_COLLECTOR_OTLP_PORT=4317 FRONTEND_PORT=3000 BACKEND_PORT=8000
d SPAN_LIST_PAGE_WALL_MS 15000; d TRACE_LIST_PAGE_WALL_MS 15000; d SESSION_LIST_PAGE_WALL_MS 15000
export STORAGE_BACKEND=minio S3_ENDPOINT_URL=http://127.0.0.1:9005
d MINIO_ROOT_USER futureagi
export S3_ACCESS_KEY="$MINIO_ROOT_USER" S3_SECRET_KEY="$MINIO_ROOT_PASSWORD" S3_BUCKET=futureagi
d PG_PORT 5432; d PG_USER futureagi; d PG_DB futureagi
export PGBOUNCER_HOST="$PG_HOST" PGBOUNCER_PORT="$PG_PORT"
export CH_PORT=9000 CH_HTTP_PORT=8123 CH_USER=default CH_USERNAME=default CH_ENABLED=true
d CH_DATABASE default; export CH25_DATABASE="${CH25_DATABASE:-$CH_DATABASE}" CH_USE_REPLICATED_ENGINES=false
d CH25_DROP_LEGACY_CDC_CHAIN true; d CH25_EVAL_LOGGER_TABLE tracer_eval_logger
d CH25_QUERY_TYPES_V2_ONLY span_list,trace_list,session_list,voice_call_list,dashboard,monitor_metrics,eval_metrics,filter_builder,trace_detail,annotation_labels
d PROPERTY_CATALOG_DATABASE property_catalog
export PROPERTY_CATALOG_CH_HOST="$CH_HOST" PROPERTY_CATALOG_CH_PORT=9000 PROPERTY_CATALOG_CH_USER=observed_catalog_reader
export FI_CH_URL="http://${CH_HOST}:8123" FI_CH_DATABASE="${FI_CH_DATABASE:-$CH25_DATABASE}" \
       FI_CH_USERNAME=default FI_CH_PASSWORD="${CH_PASSWORD:-}"
DSN="postgres://${PG_USER}:${PG_PASSWORD}@${PG_HOST}:${PG_PORT}/${PG_DB}?sslmode=disable"
export FI_PG_WRITE="$DSN" FI_PG_READ="$DSN"
d PGSSLMODE prefer
export FI_AUTH_REDIS_ADDR=127.0.0.1:6379 FI_AUTH_REDIS_PASSWORD="$REDIS_PASSWORD"
d USAGE_EVENTS_ENABLED false
export FI_GRPC_ADDR=:4317 FI_HTTP_ADDR=:4318 FI_ADMIN_ADDR=127.0.0.1:9464 \
       FI_DEAD_LETTER_FILE=/data/collector/dead_letter.jsonl \
       FI_OBSERVED_CATALOG_MODE=direct FI_OBSERVED_CATALOG_CH_URL="http://${CH_HOST}:8123" \
       FI_OBSERVED_CATALOG_CH_DATABASE="$PROPERTY_CATALOG_DATABASE" \
       FI_OBSERVED_CATALOG_CH_USERNAME=observed_catalog_writer \
       FI_OBSERVED_CATALOG_CH_PASSWORD="$PROPERTY_CATALOG_CONSUMER_PASSWORD" \
       FI_OBSERVED_CATALOG_SPOOL_DIR=/data/collector/observed-catalog \
       FI_PROPERTY_CATALOG_MODE=disabled FI_ERROR_FEED_KAFKA_BROKERS=
export AGENTCC_CONTROL_PLANE_URL=http://127.0.0.1:8000 AGENTCC_CONTROL_PLANE_TOKEN="$AGENTCC_ADMIN_TOKEN" \
       AGENTCC_SYNC_ON_STARTUP=true
d AGENTCC_SYNC_INTERVAL 60s; d AGENTCC_ALLOW_PRIVATE_PROVIDER_URLS false
d RECAPTCHA_ENABLED false; d AWS_REGION us-east-1
d TEMPORAL_TEST_EXECUTION_ENABLED true; d ERROR_LOCALIZER_BACKEND legacy
d HARNESS_PROVIDER daytona; d HOSTED_SANDBOX_PROVIDER daytona
d HARNESS_MAX_ARTIFACT_BYTES 1073741824; d ALK_HOSTED_EGRESS_UNRESTRICTED false

# --- LLM gateway providers (upstream example config unless you mount your own)
mkdir -p /etc/futureagi/secrets && chmod 700 /etc/futureagi/secrets
if [ ! -s /etc/futureagi/secrets/agentcc.yaml ]; then
  cp /etc/futureagi/agentcc.default.yaml /etc/futureagi/secrets/agentcc.yaml
fi
# Upstream mounts /dev/null here when no Vertex key is given.
[ -e /etc/futureagi/secrets/vertex.json ] || : > /etc/futureagi/secrets/vertex.json
if [ -n "${GOOGLE_VERTEX_CREDENTIALS_JSON:-}" ]; then
  (umask 077; printf '%s' "$GOOGLE_VERTEX_CREDENTIALS_JSON" > /etc/futureagi/secrets/vertex.json)
fi

# --- edge proxy on Railway's PORT
EDGE_PORT="${PORT:-8090}"
case "$EDGE_PORT" in 3000|4317|4318|6379|7233|8000|8060|8080|9005|9006|9464)
  echo "[railway] PORT=$EDGE_PORT clashes with an internal port; use 8090" >&2; exit 1 ;;
esac
sed "s/__PORT__/${EDGE_PORT}/g" /opt/railway/edge.conf.template > /etc/futureagi/edge.conf
mkdir -p /var/lib/nginx-edge /data /run/railway-edge
chmod 755 /run/railway-edge
# Keep sign-up closed from the first request after a restart (signup-guard.sh).
if [ "${FUTURE_AGI_OPEN_SIGNUP:-false}" != "true" ] && [ -f /data/.railway-signup-closed ]; then
  touch /run/railway-edge/signup-closed && chmod 644 /run/railway-edge/signup-closed
fi

echo "[railway] Future AGI v1.59.1: public URL ${PUBLIC_URL}, edge on :${EDGE_PORT}, Postgres ${PG_HOST}, ClickHouse ${CH_HOST}, model serving ${MODEL_SERVING_URL:-off}"
exec /opt/futureagi/bin/start
