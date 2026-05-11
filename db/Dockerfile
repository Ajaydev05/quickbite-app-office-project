# ── MongoDB Dockerfile ────────────────────────────────────────
FROM mongo:7.0

# Copy initialization scripts
COPY init/ /docker-entrypoint-initdb.d/

# Expose MongoDB port
EXPOSE 27017

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=5 \
  CMD mongosh --quiet --eval "db.adminCommand('ping').ok" || exit 1
