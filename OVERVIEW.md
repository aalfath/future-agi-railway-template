# Deploy and Host Future AGI on Railway

Future AGI is an open-source (Apache-2.0) platform for evaluating, observing and improving AI agents and LLM apps. It collects OpenTelemetry traces from your agents, runs evaluations on them, manages datasets, prompts and experiments, simulates conversations, and includes an OpenAI-compatible LLM gateway, all in one web app.

## About Hosting Future AGI

Future AGI's standalone install needs PostgreSQL for application data, ClickHouse for traces and analytics, and an app container that runs the Django API, a Temporal server, Redis, S3-compatible object storage, the trace collector, the LLM gateway and the UI. This template builds each from a pinned upstream release, wires them over Railway's private network, generates every password and key, and keeps all state on volumes. A small proxy in the app serves the UI, API, trace ingestion, gateway and file downloads on one Railway domain. The first boot migrates the databases and takes about 5 to 10 minutes; later restarts are quicker.

## Common Use Cases

* Trace LLM and agent calls with OpenTelemetry SDKs and inspect sessions, spans, costs and latency
* Run built-in and custom evaluations on datasets and production traces, and compare prompts and models in experiments
* Route model calls through a self-hosted, OpenAI-compatible LLM gateway with keys, budgets and guardrails

## Dependencies for Future AGI Hosting

* PostgreSQL 16 (bundled service with a volume)
* ClickHouse 25.3 (bundled service with a volume)
* An API key from at least one LLM provider (OpenAI, Anthropic, Google, AWS Bedrock and others), added in the app after deploy, for LLM-based evaluations and the gateway

### Deployment Dependencies

* Future AGI source and releases: https://github.com/future-agi/future-agi/releases
* Self-hosting docs: https://docs.futureagi.com/docs/self-hosting
* Template repository (Dockerfiles, start script, changelog): https://github.com/aalfath/future-agi-railway-template

### Implementation Details

Services in this template:

* **Future AGI**: the app (`futureagi/standalone`). Public domain, volume on `/data` (object storage, Temporal's database, collector spool). Health check `/health/`.
* **Postgres**: PostgreSQL 16 with upstream's settings (logical WAL, 200 connections), volume on `/var/lib/postgresql/data`.
* **ClickHouse**: ClickHouse 25.3 with upstream's storage policy and small-host settings, volume on `/var/lib/clickhouse`.
* **Serving**: the embedding model server for embedding-based evals and knowledge bases, volume on `/models` for downloaded models.

After deploy:

1. Open the public URL. While the first boot migrates the databases it shows "Future AGI is starting".
2. Click through the setup checks, then create your account. The first account owns the instance. After it exists, public sign-up closes automatically; invite teammates from Settings. Set `FUTURE_AGI_OPEN_SIGNUP=true` on the Future AGI service to keep sign-up open.
3. Add your LLM provider keys under Settings, then send traces: use `https://YOUR-DOMAIN` as `FI_BASE_URL` in the Future AGI SDKs (OTLP/HTTP at `/v1/traces`). The LLM gateway's OpenAI-compatible base URL is `https://YOUR-DOMAIN/gateway/v1`.

Not included: the nsjail code executor (it needs privileged containers, which Railway doesn't run; Python code evals run in the app's built-in sandbox, JavaScript code evals don't run), voice simulation (LiveKit) and hosted agent sandboxes (Daytona or E2B). Email (Mailgun) is optional: set `MAILGUN_API_KEY`, `MAILGUN_SENDER_DOMAIN` and `DEFAULT_FROM_EMAIL` on the Future AGI service. Without it, invites return a link to share and admins reset passwords with `python manage.py reset_password --email ...` in the service shell.

Updates: the services build from a public GitHub repo, so Railway shows an "update available" notice when the template moves to a new Future AGI release. Read the repo's CHANGELOG first, then apply it.

## Why Deploy Future AGI on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Future AGI on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
