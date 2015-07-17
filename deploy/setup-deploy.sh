#!/bin/bash

DIR="$(dirname "$0")"/..

(cd "$DIR" && npm install) # make sure pm2 is installed
(cd "$DIR" && node_modules/.bin/pm2 deploy ecosystem.json production setup)
