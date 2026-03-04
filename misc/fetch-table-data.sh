#! /bin/bash
# The token is already expired by the time anyone sees this
http 'https://eu-fsn-3-connect.betterstackdata.com/?table=t510758.lisisoft_debian_collector&defer-errors=true&range-from=1772589313395872&range-to=1772600113395872&sampling=1' \
        Authorization:'Bearer eyJraWQiOiJhZWEyOTA0ODkxNWZjMjQ2MjA1ZWQzN2RmOGQ3OWM1OSIsImFsZyI6IkVTMjU2In0.eyJkYXRhYmFzZSI6InQ1MTA3NTgiLCJxdWVyeV9wYXJhbXMiOnt9LCJpYXQiOjE3NzI2MDAxODIsImV4cCI6MTc3MjYwMDQ4Mn0.FqmPxe8QQ2rFIR9TPuaD8xssDfOgBgGz6JTxR38XCMNd1GfGu0vtlG4pePTt4eAgxR268v3VjM1czJKcfT2c8w' \
        < table-query.sql
