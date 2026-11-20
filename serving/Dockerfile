# Future AGI model serving: the embedding server behind embedding-based evals,
# knowledge bases and clustering (upstream's optional `ml` profile). CPU build.
FROM futureagi/serving:v1.59.1@sha256:9f44a668e49858b91d8a5405a24ed2fc2029f6bb0b885d8c29aceec55e49eac8
# Downloaded Hugging Face models go to the volume, so they survive redeploys.
ENV HF_HOME=/models \
    OTEL_ENABLED=false
EXPOSE 8080
