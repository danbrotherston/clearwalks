#!/usr/bin/env bash

# Usage: ./unique-reports.sh <last_x_days>

if [ "$1" != "" ]; then
  DAYS="$1" 
else
  DAYS="365"
fi

echo $DAYS

jq ".reports | to_entries | .[].value | if now - (.date | split(\".\")[0] + \"Z\" | fromdate) < 60*60*24*$DAYS then . else {} end | .user_email" clearwalks-export.json | sort | uniq -c

