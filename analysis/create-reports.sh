#!/usr/bin/env bash

jq '[.reports | to_entries | .[].value | if now - (.date | split(".")[0] + "Z" | fromdate) < 60*60*24*3 then . else {} end | select(.address) ] | group_by(.user_id)' clearwalks-export.json > reports.json

mustache reports.json email.mustache > bylaw_emails.txt

rm reports.json
