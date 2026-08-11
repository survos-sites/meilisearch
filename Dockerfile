# Public, reproducible production image for https://ms.survos.com.
# The FROM tag is the version pin: bump it, validate, commit, and deploy.
FROM getmeili/meilisearch:v1.53.0

# Non-secret production configuration belongs in this public image. The only
# required runtime secret is MEILI_MASTER_KEY, stored in Dokku config.
ENV MEILI_DB_PATH=/meili_data \
    MEILI_DUMP_DIR=/meili_dumps \
    TMPDIR=/meili_tmp \
    TINI_SUBREAPER=true \
    MEILI_HTTP_ADDR=0.0.0.0:7700 \
    MEILI_ENV=production \
    MEILI_NO_ANALYTICS=true \
    MEILI_HTTP_ALLOWED_ORIGINS='*' \
    MEILI_MAX_INDEX_SIZE=600GiB \
    MEILI_HTTP_PAYLOAD_SIZE_LIMIT=1GiB \
    MEILI_MAX_CONCURRENT_TASKS=4 \
    MEILI_MAX_TASKS_PER_BATCH=100 \
    MEILI_EXPERIMENTAL_CONTAINS_FILTER=true \
    MEILI_UPGRADE_DB=true

# As of v1.53.0, chatCompletions/network/multimodal/compositeEmbedders/
# getTaskDocumentsRoute have no env var or CLI flag anymore -- they're
# runtime-only, toggled via PATCH /experimental-features and persisted in the
# data directory (unlike MEILI_EXPERIMENTAL_CONTAINS_FILTER above, which is
# still a real env var). Run bin/enable-experimental-features.sh against a
# running instance after any fresh data directory init.

# State is supplied by persistent mounts, not image layers.
VOLUME ["/meili_data", "/meili_dumps", "/meili_tmp"]
EXPOSE 7700
