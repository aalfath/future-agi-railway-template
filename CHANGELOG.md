# Changelog

## v1.59.1-railway.1 (2026-11-20)

First release of the template.

- Future AGI v1.59.1 standalone app (`futureagi/standalone:v1.59.1`), model serving v1.59.1, PostgreSQL 16.16 and ClickHouse 25.3.14.14, each pinned by digest.
- One public domain through an edge proxy: UI, API, websockets, OTLP/HTTP traces, LLM gateway at `/gateway/`, stored files.
- Public sign-up closes once the first account exists (`FUTURE_AGI_OPEN_SIGNUP=true` keeps it open).
