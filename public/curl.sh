#!/bin/bash
while read line ; do
  headers=(${headers[@]} -H "$line")
done < public/headers.txt
echo ${headers[@]}
curl -X PUT \
     ${headers[@]} \
     -d @'public/example.json' \
     echo.httpkit.com
