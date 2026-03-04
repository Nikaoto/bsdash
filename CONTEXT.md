# bsdash — Session Context

## Project
TUI for BetterStack that fetches realtime telemetry data and renders it as a table chart.
Binary name: `bsdash`. Ruby project in `src/`.

## Current State
- `src/bin/bsdash` — entry point, nearly empty (just `require "bundler/setup"`)
- `src/main.rb` — throwaway Greeter placeholder, to be replaced
- `src/Gemfile` — has faraday, tty-table, tty-screen, tty-cursor, tty-reader
- `src/Gemfile.lock` — all gems installed into `src/vendor/bundle`
- `fetch-table-data.sh` — example curl for data fetch (has real JWT/table for reference)
- `table-query.sql` — example SQL query used in data fetch

## Agreed Plan

### File Structure to Create
```
src/
  bin/bsdash
  lib/
    config.rb
    cache.rb
    api/
      client.rb
      auth.rb
      sources.rb
      dashboards.rb
      charts.rb
    tui/
      app.rb
      status_bar.rb
      charts/
        table.rb
```

### CLI Flags (optparse)
- `-C/--session-cookie <v>` — write to config, exit
- `-t/--auth-token <v>` — write to config, exit
- `-s/--source <name>` — source name; cached after first use, reused unless overridden
- `-d/--dashboard <name>` — dashboard name (looked up by name, not ID)
- `-c/--chart <name>` — chart name (found inside dashboard export by name)

### Config: ~/.config/bsdash/config.json
- auth_token, session_cookie, refresh_interval (default 30s)

### Cache: ~/.config/bsdash/cache.json
- source: { team_id, table_name, data_region } — skip fetch if present
- chart: { name, query } — skip fetch if same dashboard+chart names requested

### API Flow
1. Auth: GET https://telemetry.betterstack.com/team/<team_id>/tail/cloud-jwt-token
   - Cookie: <session_cookie> → returns JWT; re-fetch on 401
2. Sources: fetch list with auth token, match by name → team_id, table_name, data_region → cache
3. Dashboards:
   a. GET /api/v2/dashboards → list of {id, name} → find by -d name to get dashboard_id
   b. GET /api/v2/dashboards/<dashboard_id>/export → full config with all chart definitions
   c. Find chart by -c name → extract query string → cache as {name, query}
4. Charts (data fetch):
   POST https://<data_region>-connect.betterstackdata.com/?table=t<team_id>.<table_name>&defer-errors=true&range-from=<epoch_us>&range-to=<epoch_us>&sampling=1
   - Body: SQL query string
   - Auth: Bearer <jwt_token>
   - Response: JSONEachRowWithProgress stream — skip "progress" rows, collect data rows
   - range-from: now-3h on first fetch, advances to last row timestamp on refresh
   - New rows appended to existing dataset

### TUI
- Two threads: fetch thread (API) + main thread (input loop via tty-reader)
- Status bar: `chart_name | refreshed 14s ago (r to refresh)  [fetching...]`
- Keys: r = force refresh (no-op if in progress), q = quit
- Redraw on: fetch complete flag, SIGWINCH
- Chart renderer: tty-table, columns fitted to terminal width, rows truncated to height
- Only chart type: table

### Build Order
1. Config + Cache read/write
2. API layer: Auth → Sources → Dashboards → Charts
3. Minimal TUI skeleton: full-screen, status bar, q to quit
4. Wire Charts::Table with static/fake data
5. Connect live data fetch to renderer
6. Fetch thread + auto-refresh timer
7. r key force refresh

## Key Technical Notes
- JWT token fetched using session cookie (from browser DevTools > Application > Cookies > _session)
- Auth token is a separate long-lived token (Bearer token for /api/v2 endpoints)
- team_id comes from sources API response
- data_region from sources (e.g. "eu-fsn-3" → "eu-fsn-3-connect.betterstackdata.com")
- table_name from sources (e.g. "lisisoft_debian_collector")
- Full table ref in URL: t<team_id>.<table_name> (with underscore, not hyphen)
- range-from/range-to are epoch microseconds
- Response format: JSONEachRowWithProgress (one JSON object per line, some are progress updates)
