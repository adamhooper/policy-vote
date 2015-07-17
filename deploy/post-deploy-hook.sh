#!/bin/sh

DIR="$(dirname "$0")"/..

set -x
set -e

npm install --production

node_modules/.bin/gulp
touch /mnt/policy-vote/users.csv /mnt/policy-vote/votes.csv
ln -s /mnt/policy-vote/users.csv "$DIR"/data/users.csv
ln -s /mnt/policy-vote/votes.csv "$DIR"/data/votes.csv

export APPLICATION_SECRET=`cat /opt/policy-vote/APPLICATION_SECRET`
pm2 startOrReload ecosystem.json --env production -i 1"
