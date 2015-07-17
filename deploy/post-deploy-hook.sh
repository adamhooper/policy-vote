#!/bin/sh

set -x

npm install --production

node_modules/.bin/gulp
touch /mnt/policy-vote/users.csv /mnt/policy-vote/votes.csv
ln -sv /mnt/policy-vote/users.csv data/users.csv
ln -sv /mnt/policy-vote/votes.csv data/votes.csv

export APPLICATION_SECRET=`cat /opt/policy-vote/APPLICATION_SECRET`
pm2 startOrReload ecosystem.json --env production -i 1"
