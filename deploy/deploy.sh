#!/bin/bash

# Deploy the latest version of this app
#
# The server (whose DNS name is in ecosystem.json) must have been provisioned
# using script/provision-ec2.sh.

DIR="$(dirname "$0")"/..
DIST_DIR="$DIR"/dist
BUCKET="macleans-policy-vote-2015"

set -e

(cd "$DIR" && gulp)

upload() {
  filename="$1"
  mime_type="$2"

  echo "Uploading $filename ($mime_type)"

  src="$DIST_DIR"/"$filename"
  dest="$BUCKET"/"$filename"

  aws s3 cp "$src" s3://"$dest" \
    --acl public-read \
    --content-type "$mime_type" \
    --cache-control no-cache
}

upload_with_gzip() {
  filename="$1"
  mime_type="$2"

  echo "Uploading $filename ($mime_type) and a .gz copy"

  src="$DIST_DIR"/"$filename"
  dest="$BUCKET"/"$filename"

  aws s3 cp "$src" s3://"$dest" \
    --acl public-read \
    --content-type "$mime_type" \
    --cache-control no-cache

  gzip -f -k "$src"
  aws s3 cp "$src".gz s3://"$dest".gz \
    --acl public-read \
    --content-type "$mime_type" \
    --content-encoding gzip \
    --cache-control no-cache
}

upload_with_gzip index.css 'text/css; charset=utf-8'
upload_with_gzip index.en.js 'application/javascript; charset=utf-8'
upload_with_gzip index.fr.js 'application/javascript; charset=utf-8'
upload fonts/FontAwesome.otf application/vnd.ms-opentype
upload fonts/fontawesome-webfont.eot application/vnd.ms-fontobject
upload fonts/fontawesome-webfont.svg image/svg+xml
upload fonts/fontawesome-webfont.ttf application/x-font-ttf
upload fonts/fontawesome-webfont.woff application/octet-stream
upload fonts/fontawesome-webfont.woff2 application/octet-stream

(cd "$DIR" && npm install) # make sure pm2 is installed
(cd "$DIR" && node_modules/.bin/pm2 deploy ecosystem.json production)
