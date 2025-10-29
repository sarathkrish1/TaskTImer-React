#!/bin/bash
set -e

# Fetch crumb and save cookie jar
curl -c /tmp/cjar -s 'http://localhost:8080/crumbIssuer/api/json' > /tmp/crumb.json
crumb=$(sed -n 's/.*"crumb":"\([^"]*\)".*/\1/p' /tmp/crumb.json)
echo "Using crumb:$crumb"

# Post kubeconfig credential
curl -v -b /tmp/cjar -X POST 'http://localhost:8080/credentials/store/system/domain/_/createCredentials' \
  -H 'Content-Type: application/xml' -H "Jenkins-Crumb: $crumb" --data-binary @/tmp/kubeconfig-cred.xml

# Post docker username/password credential
curl -v -b /tmp/cjar -X POST 'http://localhost:8080/credentials/store/system/domain/_/createCredentials' \
  -H 'Content-Type: application/xml' -H "Jenkins-Crumb: $crumb" --data-binary @/tmp/docker-cred.xml
