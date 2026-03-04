
# Stream Plan

**Start**: 03 March, 23:51

- [DONE] get accustomed to BetterStack and its various tools
- [SKIP] build small CLI tool in Ruby
- [DONE] build scaffolding or fakers for testing
- [IN PROGRESS] build the tool
  - [DONE] fetch all dashboards data using auth token and dump to STDOUT
  - [DONE] fetch all charts and dump to STDOUT
  - [DONE] start black/white TUI that takes static text chart and renders it
  - [DONE] quit key
  - [DONE] auto refresh at intervals
  - [DONE] force refresh key
  - [SKIP] number refresh
  - [DONE] table render
  - [DONE] config file (read auth key from there)
  - [DONE] cache each dash and chart. cache current chart
  - [SKIP] chart navigation
  - [SKIP] dash navigation
  - [DONE] cache token
- [MAYBE?] write tests around the tool
- clean up the git repo

## Notes

### (3:03) JavaScript transform script

The .reduce() based concat can be optimized for simplicity, memory and runtime
by using a simple for loop.

```javascript
async (existingDataByQuery, newDataByQuery, completed) => {
  for (const key in newDataByQuery)
    existingDataByQuery[key] = existingDataByQuery[key].concat(newDataByQuery[key])
  return existingDataByQuery
}
```

Execution time comparison, 10 samples:
```
|--------|---------|
| reduce | forloop |
|--------|---------|
| 0.7    | 0.8     |
| 0.7    | 0.7     |
| 0.7    | 0.6     |
| 0.7    | 0.7     |
| 0.7    | 0.91    |
| 0.6    | 0.7     |
| 1.1    | 1.1     |
| 4.8    | 0.7     |
| 0.7    | 0.7     |
| 0.7    | 0.7     |
|--------|---------|
| 11.4s  | 7.61s   |
|--------|---------|
```

### (3:26) Timezone bug
- Just select time from my source and display it as a table in a chart.
- Logs ingested by BS from my linux box show 3am GMT+4.
- BS probably zeroes the timezone on them.
- Then it detects my browser's timezone as GMT+4.
- Then it displays the 3am log as 7am log (adding +4 unnecessarily).

### (6:29) API defined

## Telemetry dashboard TUI

### Chart display
- Flags
  - `dashboard_id`
  - `chart_id`
  - `auth_token`
- remember last token used (either through flag or config), dash and chart and
  display it with bsdash
- each new chart display is cached and we can cycle through them using j/k keys
- we can cycle through dashboards using h/l keys
- display `dashboard_id` and `dashboard_name` atop
- display `chart_id` and `chart_name` atop as well
- force refresh using `r` key. Don't start new refresh if one already in progress
- delete chart from cache using `d` key. Delete the entire dash when last chart is deleted
- the 3 above should look something like
  `dash_name (h/k) [1/x] | chart_name (j/k) [1/x] | last_refresh (r)...`
- `[1/x]` means you're viewing dash/chart number 1 out of a total of x
- `q` to quit
- config will be located at ~/.config/bsdash/config.json
  - `auth_token`
  - `refresh_interval`
  - colors and other visual config (IF WE HAVE EXTRA TIME)
- cache will be located at ~/.config/bsdash/cache.json
  - holds all dashboards and their charts
  - `last_chart_location` holds `{dash_id, chart_id}` that was last in view
- supported chart types
  - text
  - number
  - table
  - bar with single var (IF WE HAVE EXTRA TIME)
  - bar with multiple vars (IF WE HAVE EXTRA TIME)
  - formatted text (IF WE HAVE EXTRA TIME)


Fetch all dashboards and charts for given user and caches them all:
```bash
bsdash -t auth_token
```

Displays single specific chart:
```bash
bsdash -t auth_token -d dashboard_id -c chart_id
```

### Display bar graphs
What a bar graph may look like.
3 vars: XYZ (each different color)
```
          Z
          Z  YZ   Z
        X Z  YZ   Z
    X   XYZ XYZ  YZ  Y
XYZ XYZ XYZ XYZ XYZ XYZ
```

## Status page CLI

prints out status page on CLI https://niko-company.betteruptime.com/
  - `-w/--watch` flag that refreshes it every 30 seconds



