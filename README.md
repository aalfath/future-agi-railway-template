[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/future-agi?utm_medium=integration&utm_source=button&utm_campaign=future-agi)

# Future AGI on Railway

Railway template for [Future AGI](https://github.com/future-agi/future-agi) **v1.59.1**, the open-source platform for evaluating, observing and improving AI agents. It deploys upstream's standalone install as four Railway services that build from this repo:

| Folder | Railway service | Base image (pinned) | Volume |
|---|---|---|---|
| `app/` | Future AGI (public) | `futureagi/standalone:v1.59.1@sha256:9fb56deb…63e88` | `/data` |
| `postgres/` | Postgres | `postgres:16.16@sha256:3950ad7c…0382f` | `/var/lib/postgresql/data` |
| `clickhouse/` | ClickHouse | `clickhouse/clickhouse-server:25.3.14.14-alpine@sha256:a4e8cf46…8ae62` | `/var/lib/clickhouse` |
| `serving/` | Serving | `futureagi/serving:v1.59.1@sha256:9f44a668…9eac8` | `/models` |

## What the wrapper adds

- `app/start.sh` maps the template's variables (private hosts, generated secrets, the Railway domain) onto the settings upstream's `docker-compose.yml` passes, then runs upstream's entrypoint (`/opt/futureagi/bin/start`).
- `app/edge.conf.template` is an nginx proxy on Railway's `PORT`, so one domain serves the UI, the API and websockets, OTLP/HTTP traces (`/v1/traces`), the LLM gateway (`/gateway/`) and stored files.
- `app/signup-guard.sh` closes public sign-up once the first account exists (upstream's OSS build leaves it open to anyone). `FUTURE_AGI_OPEN_SIGNUP=true` keeps it open.
- `clickhouse/` carries upstream's ClickHouse config files (storage policy, small-host settings, password from `CLICKHOUSE_PASSWORD`) plus an IPv6 listen for Railway's private network.

## Variables (set by the template)

| Service | Variable | Value |
|---|---|---|
| Postgres | `POSTGRES_PASSWORD` | generated |
| ClickHouse | `CLICKHOUSE_PASSWORD` | generated |
| Future AGI | `PG_HOST`, `CH_HOST`, `MODEL_SERVING_URL` | private domains of the other services |
| Future AGI | `PG_PASSWORD`, `CH_PASSWORD` | references to the passwords above |
| Future AGI | `SECRET_KEY`, `REDIS_PASSWORD`, `MINIO_ROOT_PASSWORD`, `AGENTCC_INTERNAL_API_KEY`, `AGENTCC_ADMIN_TOKEN`, `AGENTCC_WEBHOOK_SECRET`, `PROPERTY_CATALOG_CH_PASSWORD`, `PROPERTY_CATALOG_CONSUMER_PASSWORD` | generated |
| Future AGI | `INTEGRATION_ENCRYPTION_KEY` | generated Fernet key (43 URL-safe characters plus `=`) |
| Future AGI | `PORT` | `8090` (the edge proxy) |

Nothing is prompted at deploy. Optional, on the Future AGI service: `FUTURE_AGI_OPEN_SIGNUP`, `FUTURE_AGI_TELEMETRY_DISABLED=true` (upstream's anonymous deployment telemetry), Mailgun email (`MAILGUN_API_KEY`, `MAILGUN_SENDER_DOMAIN`, `DEFAULT_FROM_EMAIL`), and provider keys such as `OPENAI_API_KEY` (you can also add keys in the app).

Not included: the nsjail `code-executor` (needs privileged containers), voice simulation (LiveKit) and hosted agent sandboxes (Daytona/E2B).

## Updates

Railway shows deployers an "update available" notice when `main` changes. Each version bump changes the pinned image digests in the Dockerfiles and adds an entry to [CHANGELOG.md](CHANGELOG.md), with breaking changes first. Read it before you apply an update. Keep the Postgres major version (16): upstream's bootstrap refuses a database made by another C library or major version.
