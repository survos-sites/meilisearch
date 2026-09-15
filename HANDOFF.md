# Meilisearch handoff

## Production

- The engine is the Dokku app `meilisearch` at `https://ms.survos.com`.
- It runs Meilisearch `1.53.0` from this repository's Dockerfile.
- Persistent server paths are mounted as follows:
  - `/mnt/volume-1/meilisearch-data` -> `/meili_data`
  - `/mnt/volume-1/meili-dumps` -> `/meili_dumps`
  - `/mnt/volume-1/meili-tmp` -> `/meili_tmp`
- The former systemd service and `/usr/bin/meilisearch` were removed. The
  persistent production data was retained and must not be deleted.
- Dokku deployment checks **must stay disabled** for `web`, because two
  Meilisearch processes cannot open the same LMDB database at once. A
  zero-downtime deploy starts the new container while the old one still holds
  the lock, so the new process cannot open `/meili_data` and dies with
  `Internal error: Resource temporarily unavailable (os error 11)`, retrying on
  a widening backoff until the check gives up and the release is rejected. The
  error names a resource problem and reads like one; it is a lock.

      dokku checks:disable meilisearch web

  This is not optional configuration and it is not belt-and-braces: with checks
  enabled, **every** push fails, and the failure looks like the new version is
  broken. It was lost once already — `checks:report` read
  `Checks disabled list: none` on 2026-09-15 and a push was rejected — and an
  `app.json` `healthchecks` block had been added, which reintroduces the same
  check by the newer mechanism even when the legacy one is disabled. That block
  has been removed; do not add one. A startup healthcheck cannot succeed for
  this app by construction.
- The production master key changed during migration. Existing key records are
  still present, but clients holding values derived from the former master key
  must be updated. This API-key rotation remains the main production follow-up.
- Keep `MEILI_MASTER_KEY` in Dokku config only. Do not commit it.
- The owner will perform and report future Dokku pushes.

Deploying a new version:

```bash
# once, if `dokku checks:report meilisearch` shows nothing in the disabled list
ssh fsn1 checks:disable meilisearch web

git push dokku main
ssh fsn1 ps:report meilisearch
curl https://ms.survos.com/health
```

Useful production checks:

```bash
dokku ps:report meilisearch
dokku logs meilisearch --tail
curl https://ms.survos.com/health
```

## Local development

- Start the production-equivalent image from this repository:

  ```bash
  cd ~/sites/meilisearch
  bin/run.sh
  ```

- Stop it with `docker compose down`.
- Local storage is configured privately in `.env` and currently points to
  `/media/tac/extradrive1/meilisearch`, the non-root disk.
- Local indexes intentionally start empty and should be rebuilt. Do not migrate
  either of the old local databases.
- The local master key lives only in this repository's ignored `.env` file.
- KPA's `.env.local` now uses `http://127.0.0.1:7700` and that local key; an
  authenticated index request returned HTTP 200.

## Repository layout

- `Dockerfile` is the shared production/local definition and pins the version.
- `docker-compose.yml` supplies only the local secret and storage mounts.
- `bin/run.sh` creates private defaults when needed, builds the image, starts
  Compose, and waits for `/health`.
- Meilisearch has been removed from `~/sites/docker/docker-compose.yaml`; that
  shared stack should no longer own port 7700 or Meilisearch data.

