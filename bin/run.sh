#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_dir"

if [[ ! -f .env ]]; then
    umask 077
    printf 'MEILI_MASTER_KEY=%s\n' "$(openssl rand -hex 32)" > .env
    printf 'MEILI_STORAGE_ROOT=%s\n' "${MEILI_STORAGE_ROOT:-$HOME/.local/share/meilisearch}" >> .env
    echo 'Created a new local master key in .env.'
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

mkdir -p "$MEILI_STORAGE_ROOT"/{data,dumps,tmp}

if [[ ! -d "$MEILI_STORAGE_ROOT/data/data.ms" ]]; then
    echo "Starting with an empty database at $MEILI_STORAGE_ROOT/data."
fi

docker compose up -d --build

for attempt in {1..30}; do
    if curl --fail --silent http://127.0.0.1:7700/health >/dev/null; then
        echo 'Meilisearch is available at http://127.0.0.1:7700.'
        MEILI_SERVER=http://127.0.0.1:7700 "$repo_dir/bin/enable-experimental-features.sh"
        exit 0
    fi
    sleep 1
done

echo 'Meilisearch did not become healthy; inspect with: docker compose logs meilisearch' >&2
exit 1
