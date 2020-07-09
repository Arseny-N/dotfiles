#!/bin/bash


adb forward tcp:4001 localabstract:chrome_devtools_remote
curl -v localhost:4001/json/list -o tabs.json
jq -r '.[] | .title + "  " + .url' tabs.json > tabs.txt
