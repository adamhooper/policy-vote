#!/bin/sh

set -x
set -e

rm -f data/users.csv data/votes.csv
touch /mnt/policy-vote/users.csv /mnt/policy-vote/votes.csv
ln -s /mnt/policy-vote/users.csv data/users.csv
ln -s /mnt/policy-vote/votes.csv data/votes.csv

npm install --production

node_modules/.bin/gulp

export APPLICATION_SECRET="$(cat /opt/policy-vote/APPLICATION_SECRET)"
pm2 startOrReload ecosystem.json --env production -i 1"
