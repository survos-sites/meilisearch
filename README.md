# Meilisearch production engine

Public, Dockerfile-driven deployment for the Meilisearch engine at
`https://ms.survos.com`. This is not the Symfony SearchBench application: that
remains a separate application at `https://meili.survos.com`.

## Version and configuration

The upstream image version and all non-secret production configuration are
defined in `Dockerfile`. The only required runtime secret is
`MEILI_MASTER_KEY`; keep it in the deployment platform's secret configuration,
never in this repository.

Existing API keys are derived from the master key. Preserve the master key
during routine image upgrades; rotate it only as a coordinated credential
migration across every client.

## Persistent state

Mount persistent host or volume storage at:

```text
/meili_data
/meili_dumps
/meili_tmp
```

Never run two Meilisearch processes against the same `/meili_data` directory.

## Dokku deployment

The production app is `meilisearch` and listens on port 7700:

```bash
dokku apps:create meilisearch
dokku config:set --no-restart meilisearch MEILI_MASTER_KEY='<secret>'
dokku ports:set meilisearch http:80:7700

dokku storage:mount meilisearch /path/to/data:/meili_data
dokku storage:mount meilisearch /path/to/dumps:/meili_dumps
dokku storage:mount meilisearch /path/to/tmp:/meili_tmp

git remote add dokku dokku@your-host:meilisearch
git push dokku main
```

Set the public domain and TLS using the normal Dokku domain and certificate
workflow after the previous service has been stopped.

## Upgrade workflow

1. Review upstream release notes and migration warnings.
2. Change the `FROM` tag in `Dockerfile`.
3. Build and test the image locally.
4. Commit the version bump.
5. Stop any legacy process that uses the production database.
6. Push `main` to Dokku and monitor startup and upgrade tasks.
7. Verify health, version, index/document counts, and representative searches.

Meilisearch databases are version-specific. This image currently enables the
experimental dumpless upgrade mechanism; preserve a rollback copy before a
production version migration.

## Local development

This repository describes production. Local development can use any compatible
Compose stack, for example:

```yaml
services:
  meilisearch:
    image: getmeili/meilisearch:v1.53.0
    ports: ["7700:7700"]
    environment:
      MEILI_MASTER_KEY: local-development-only
    volumes: ["./var/meili:/meili_data"]
