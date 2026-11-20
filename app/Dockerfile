# Future AGI standalone app container (API, Temporal dev server, Redis, object
# storage, trace collector, LLM gateway, Python code-eval sandbox and the UI
# under supervisord), plus a small edge nginx that puts every public part on
# one Railway domain.
FROM futureagi/standalone:v1.59.1@sha256:9fb56deb1180a27d026cd6a65a13e7fb2dfaa83d031b63aad6c7a1d9d1663e88

COPY agentcc.yaml /etc/futureagi/agentcc.default.yaml
COPY edge.conf.template /opt/railway/edge.conf.template
COPY start.sh signup-guard.sh /opt/railway/
RUN chmod 0755 /opt/railway/start.sh /opt/railway/signup-guard.sh \
    && mkdir -p /var/lib/nginx-edge \
    && printf '\n[program:edge]\ncommand=nginx -c /etc/futureagi/edge.conf -g "daemon off;"\npriority=10\nautorestart=true\nstdout_logfile=/dev/stdout\nstdout_logfile_maxbytes=0\nredirect_stderr=true\n\n[program:signup-guard]\ncommand=/opt/railway/signup-guard.sh\npriority=50\nautorestart=true\nstdout_logfile=/dev/stdout\nstdout_logfile_maxbytes=0\nredirect_stderr=true\n' >> /etc/futureagi/supervisord.conf

# Railway health checks the edge port; the image's own HEALTHCHECK is unused.
EXPOSE 8090
ENTRYPOINT ["/opt/railway/start.sh"]
CMD []
