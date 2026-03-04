# Setup

- `cd src`
- `bundle install`
- Log into betterstack
- Go into DevTools > Application > Cookies and get _session
- Double-click the value of _session and copy it
- Run `bsdash --session-cookie/-C <cookie>` to cache the session cookie
  (it will expire in ~3 months)
- Run `bsdash --auth-token/-t <auth_token>` to cache the auth token
- Run `bsdash -s source -d dash_name -c chart_name` to begin

## Caveats
- **Only works with table charts!**
- Won't work for projects that have duplicate dashboard names

# Fetching Data

1. First we need the session cookie and the auth token to be set.

2. Then we obtain jwt token (and keep re-obtaining it time-to-time)
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

6. Fetch dashboard config to get charts and queries
```
curl --request GET   --url "https://telemetry.betterstack.com/api/v2/dashboards/693277/export"   --header "Authorization: Bearer <auth_token>"
```

7. Fetch realtime data from dashboard using query from specified chart
```
POST `https://<data_region>-connect.betterstackdata.com/?table=t<team_id>.<table_name>&defer-errors=true&range-from=x&range-to=y&sampling=1`
Authorization: Bearer <jwt_token>

Payload
<chart_query>
```

8. Keep fetching new data and merging with existing data on each refresh
   (automatic interval or 'r' key press)

9. Rerender on data refresh or window resize
