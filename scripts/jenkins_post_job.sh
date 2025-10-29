#!/bin/bash
set -e

# Get crumb and cookie jar
curl -c /tmp/cjar -s 'http://localhost:8080/crumbIssuer/api/json' > /tmp/crumb.json
crumb=$(sed -n 's/.*"crumb":"\([^"]*\)".*/\1/p' /tmp/crumb.json)
echo "Using crumb:$crumb"

# Post job config
curl -v -b /tmp/cjar -X POST 'http://localhost:8080/createItem?name=timer-app-deployment' \
  -H 'Content-Type: application/xml' -H "Jenkins-Crumb: $crumb" --data-binary @/tmp/job-config.xml
