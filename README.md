# Setup

- `cd src`
- `bundle install`
- Obtain BetterStack session cookie
  - Log into betterstack
  - Go into DevTools > Application > Cookies and get _session
  - Double-click the value of _session and copy it
- Run `bsdash --session-cookie/-C <cookie>` to cache the session cookie
  (it will expire in ~3 months)
- Run `bsdash -t <auth_token> -s <source> -d <dash_name> -c <chart_name>` to begin.

  Refer to the images to find each field:
  ![](dash_source_location.png)
  ![](chart_location.png)
  
  So, in my case, I would do:
  ```
  bsdash -t my_auth_token -s lisisoft-debian-collector -d main -c "Memory usage by service"
  ```
  
- Just run `bsdash` with no flags to see the same chart next time you want to
  monitor it. (All settings and flags are cached in `~/.config/bsdash/`)

- Want to view a different chart in the same dashboard? Only specify the chart name.
  ```
  bsdash -c 'My new chart'
  ```
  Everything else was already cached, so you only need to specify what changed.

- Session cookie expired? (Will happen every 3 months!) Just grab a new session cookie from your browser and save it in bsdash:
  ```
  bsdash -C session_cookie
  ```
  Then running `bsdash` will get you back to where you left off.

## Caveats
- This is a demo, so it only works with table charts.
- Won't work for projects that have duplicate dashboard names.

# How It Works

1. First we need the session cookie and the auth token to be set.

2. Then we obtain a jwt token (and keep re-obtaining it time-to-time)
```
GET https://telemetry.betterstack.com/team/t<team_id>/tail/cloud-jwt-token
Cookie: <session_cookie>
```

3. Then we need the source to be set using `-s/--source lisisoft-debian-collector`

4. Fetch sources and find one with the `.name` as `<source_name>` (specified with `-s` flag).
   We obtain `team_id`, `table_name` and `data_region`.

5. Fetch specified dashboard
```
curl --request GET   --url "https://telemetry.betterstack.com/api/v2/dashboards"   --header "Authorization: Bearer <auth_token>"
```

6. Fetch dashboard config to get charts and their queries
```
curl --request GET   --url "https://telemetry.betterstack.com/api/v2/dashboards/693277/export"   --header "Authorization: Bearer <auth_token>"
```

7. Fetch realtime data from dashboard using query from specified chart
```
POST `https://<data_region>-connect.betterstackdata.com/?table=t<team_id>.<table_name>&defer-errors=true&range-from=x&range-to=y&sampling=1`
Authorization: Bearer <jwt_token>

<chart_query>
```

8. Keep fetching new data and merging with existing data on each refresh
   (automatic interval or 'r' key press)

9. Rerender on data refresh or window resize
