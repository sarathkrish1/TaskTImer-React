#!/bin/bash
# Get admin password from Jenkins container
ADMIN_PWD=$(cat /var/jenkins_home/secrets/initialAdminPassword)

# Get crumb
CRUMB=$(curl -u "admin:$ADMIN_PWD" -s 'http://localhost:8080/crumbIssuer/api/json' | sed -n 's/.*"crumb":"\([^"]*\)".*/\1/p')

# Create the pipeline job
curl -v -u "admin:$ADMIN_PWD" \
  -H "Jenkins-Crumb: $CRUMB" \
  -H "Content-Type: text/xml" \
  --data-binary @/tmp/job-config.xml \
  "http://localhost:8080/createItem?name=timer-app-deployment"

# Create kubeconfig credential
curl -v -u "admin:$ADMIN_PWD" \
  -H "Jenkins-Crumb: $CRUMB" \
  -H "Content-Type: text/xml" \
  --data-binary @/tmp/kubeconfig-cred.xml \
  "http://localhost:8080/credentials/store/system/domain/_/createCredentials"

# Create placeholder Docker credential
curl -v -u "admin:$ADMIN_PWD" \
  -H "Jenkins-Crumb: $CRUMB" \
  -H "Content-Type: text/xml" \
  --data-binary @/tmp/docker-cred.xml \
  "http://localhost:8080/credentials/store/system/domain/_/createCredentials"