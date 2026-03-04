#! /bin/bash
http 'https://eu-fsn-3-connect.betterstackdata.com/?table=t510758.lisisoft_debian_collector&defer-errors=true&range-from=1772573731632000&range-to=1772584531632000&sampling=1' \
        Authorization:'Bearer eyJraWQiOiJhZWEyOTA0ODkxNWZjMjQ2MjA1ZWQzN2RmOGQ3OWM1OSIsImFsZyI6IkVTMjU2In0.eyJkYXRhYmFzZSI6InQ1MTA3NTgiLCJxdWVyeV9wYXJhbXMiOnt9LCJpYXQiOjE3NzI1OTAyMjksImV4cCI6MTc3MjU5MDUyOX0.7KP5Hf78HV98-wQG6HJP11VXKU9Z1ohF1Kxa9t7MTc1AwdatOs05rVU7M4RLVtf9xXPm55UAUrUBRM52_BdgBA' \
        < table-query.sql
