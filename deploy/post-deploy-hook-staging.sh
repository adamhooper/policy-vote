#!/bin/sh

set -x
set -e

rm -f data/votes.csv
touch /mnt/policy-vote/votes.csv
ln -s /mnt/policy-vote/votes.csv data/votes.csv

npm install --production

node_modules/.bin/gulp

export APPLICATION_SECRET="$(cat /opt/policy-vote/APPLICATION_SECRET)"
export ASSET_BASE="http://macleans-policy-vote-2015-staging.s3-website-us-east-1.amazonaws.com"

pm2 startOrReload ecosystem.json --env production -i 1
