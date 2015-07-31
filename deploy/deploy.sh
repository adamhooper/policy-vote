#!/bin/bash

# Deploy the latest version of this app
#
# The server (whose DNS name is in ecosystem.json) must have been provisioned
# using script/provision-ec2.sh.

DIR="$(dirname "$0")"/..
DIST_DIR="$DIR"/dist

set -e

(cd "$DIR" && gulp)

for f in $(ls "$DIST_DIR"/*.css "$DIST_DIR"/*.js "$DIST_DIR"/*.js.map); do
  aws s3 cp "$f" "s3://macleans-policy-vote-2015" \
    --acl public-read \
    --cache-control no-cache
done
aws s3 cp "$DIST_DIR"/fonts "s3://macleans-policy-vote-2015" \
  --recursive \
  --acl public-read \
  --cache-control no-cache

(cd "$DIR" && npm install) # make sure pm2 is installed
(cd "$DIR" && node_modules/.bin/pm2 deploy ecosystem.json production)
