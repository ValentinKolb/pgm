# pgm

A small, opinionated Bash CLI for managing PostgreSQL application databases.

One database per app, one user per database, password auth. Works with plain Postgres or with PgBouncer in front. Runs on the Postgres host and uses the local Unix socket — no SSH, no remote agents, no PgBouncer config touched.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/valentinkolb/pgm/main/install.sh | sudo bash
```

Drops `pgm` into `/usr/local/bin`, copies `pgm.conf.example` to `/etc/pgm/`, and adds a symlink at `/usr/sbin/pgm` so `sudo pgm` works on RHEL/Fedora (where `/usr/local/bin` isn't in sudoers' `secure_path`). Then `cp /etc/pgm/pgm.conf.example /etc/pgm/pgm.conf` if you want permanent config overrides. Override install locations with `PGM_PREFIX` / `PGM_CONFDIR`, or pin a tag with `PGM_REF=v1.0.0`.

Requires `bash` 4+, `psql`, `openssl`, and a Unix-socket-trusted Postgres superuser (PostgreSQL 14+).

## create

Create a new app database with a dedicated owner role. Convention: database is `<app>`, owner role is `<app>_app`.

```sh
sudo pgm create blog
```

Generates a 32-char alphanumeric password, sets schema permissions (`REVOKE ... FROM PUBLIC` + `GRANT ... TO <app>_app`), enables `pg_stat_statements`, and writes credentials to `$HOME/.pg-app-secrets/<app>.env` (chmod 600).

```
PG_HOST=localhost
PG_PORT=5432
PG_DATABASE=blog
PG_USER=blog_app
PG_PASSWORD=<32-char alphanumeric>
PG_URL=postgresql://blog_app:…@localhost:5432/blog
```

## delete

Drop the database, the role, and the `.env` file. Refuses to act unless the role owns the database (primary defense against deleting unrelated DBs). Requires you to type the app name to confirm.

```sh
sudo pgm delete blog
```

## list

List all databases owned by an `*_app` role with their size.

```sh
sudo pgm list
```

## info

Show database size, active connections, installed extensions, and the masked URL pattern.

```sh
sudo pgm info blog
```

## rotate-password

Generate a new password and update both the role and the `.env` file. Hard cut — the old password stops working immediately.

```sh
sudo pgm rotate-password blog
```

## Configuration

All settings have env-var overrides. Permanent defaults live in `/etc/pgm/pgm.conf` (sourced by the script with `:=` syntax so env-vars take precedence).

| Variable | Default | Description |
| --- | --- | --- |
| `PGM_DB_HOST` | `localhost` | Host shown in connection strings |
| `PGM_DB_PORT` | `5432` | Port shown in connection strings (set `6432` for PgBouncer URIs) |
| `PGM_SECRETS_DIR` | `$HOME/.pg-app-secrets` | Where `.env` files are stored |
| `PGM_PSQL_CMD` | `sudo -u postgres psql` | How to invoke psql with admin rights |
| `PGM_SAVE_ENV` | `true` | Save `.env` file on `create` |
| `PGM_PG_STAT_STATEMENTS` | `true` | Enable `pg_stat_statements` on `create` |
| `PGM_SUGGEST_HBA_CHANGE` | `true` | Print a `pg_hba.conf` reminder after `create` |

`pgm` itself never opens a TCP connection — it always speaks to Postgres over the local Unix socket via `PGM_PSQL_CMD`. The `PGM_DB_HOST` / `PGM_DB_PORT` variables are display-only: they shape the connection string written into `.env` and printed to the terminal so applications can use it.

## Setups

### Linux (default)

`sudo -u postgres psql` works out of the box on Debian/Ubuntu/RHEL. Nothing to configure beyond `sudo ./install.sh`.

### macOS (Homebrew)

Homebrew Postgres runs as the current user — there is no `postgres` system user. Override the psql command and the secrets directory:

```sh
export PGM_PSQL_CMD="psql -d postgres"
pgm create blog
```

Drop the export into `/etc/pgm/pgm.conf` (using `:=`) for permanence.

### Cloud / managed Postgres (RDS, Supabase, Neon, …)

When you can only reach Postgres over TCP and have a superuser-equivalent role, point `PGM_PSQL_CMD` at it. Use `~/.pgpass` for the password rather than embedding it.

```sh
export PGM_PSQL_CMD="psql -h db.example.com -U pgm_admin -d postgres"
export PGM_DB_HOST="db.example.com"
export PGM_DB_PORT="5432"
pgm create blog
```

Caveats:
- Many managed providers restrict `CREATE EXTENSION pg_stat_statements`. Set `PGM_PG_STAT_STATEMENTS=false` if so.
- Managed providers handle `pg_hba.conf` for you. Set `PGM_SUGGEST_HBA_CHANGE=false` to silence the reminder.
- The role you connect as must be allowed to `CREATE ROLE` and `CREATE DATABASE`.

## License

MIT — see [LICENSE](./LICENSE).
