#!/usr/bin/env bash
# As of Meilisearch v1.53.0, several experimental features no longer have an
# env var / CLI flag; they are runtime-only, set via PATCH /experimental-features
# and persisted in the data directory. The Dockerfile's MEILI_EXPERIMENTAL_*
# vars for these are dead — this script is the real switch. Re-run it any time
# the data directory is rebuilt from scratch (env-var-only flags like
# MEILI_EXPERIMENTAL_CONTAINS_FILTER are unaffected and still work via Docker).
set -euo pipefail

server="${MEILI_SERVER:-http://127.0.0.1:7700}"
: "${MEILI_MASTER_KEY:?Set MEILI_MASTER_KEY before running this script}"

curl --fail --silent --show-error \
    -X PATCH \
    -H "Authorization: Bearer ${MEILI_MASTER_KEY}" \
    -H 'Content-Type: application/json' \
    -d '{
        "chatCompletions": true,
        "network": true,
        "multimodal": true,
        "compositeEmbedders": true,
        "getTaskDocumentsRoute": true
    }' \
    "${server}/experimental-features" \
    | python3 -m json.tool

echo "Experimental features updated at ${server}."
