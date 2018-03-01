# Steemhunt Back-end

## Stacks
- Ruby 2.4
- Rails 5
- Nginx / Puma
- PostgreSQL

## Development settings

### Add DB user
```
PG_UNAME=steemhunt
psql -d postgres -c "CREATE USER $PG_UNAME;"
psql -d postgres -c "ALTER USER $PG_UNAME CREATEDB;"
psql -d postgres -c "ALTER USER $PG_UNAME WITH SUPERUSER;"

rails db:drop db:create db:migrate
```
