#!/bin/bash

# Deploy a standalone version of the app.
#
# There is no server. We just use S3 to host the website.
# Also, we don't gzip content. This project is finished, meaning it's
# low-traffic now. Better to wash our hands of it than to invest time into
# making it perfect.

DIR="$(dirname "$0")"/..
DIST_DIR="$DIR"/dist
BUCKET="macleans-policy-vote-2015.adamhooper-projects.com"

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

upload index.html 'text/html; charset=utf-8'
upload index.fr.html 'text/html; charset=utf-8'
upload index.css 'text/css; charset=utf-8'
upload index.en.js 'application/javascript; charset=utf-8'
upload index.fr.js 'application/javascript; charset=utf-8'
upload standalone-policy-score.html 'application/javascript; charset=utf-8'
upload standalone-policy-score.en.js 'application/javascript; charset=utf-8'
upload statistics/n-votes-by-policy-id 'application/json'
upload favicon.ico 'image/x-icon'
upload pym.js 'application/javascript; charset=utf-8'
upload fonts/FontAwesome.otf application/vnd.ms-opentype
upload fonts/fontawesome-webfont.eot application/vnd.ms-fontobject
upload fonts/fontawesome-webfont.svg image/svg+xml
upload fonts/fontawesome-webfont.ttf application/x-font-ttf
upload fonts/fontawesome-webfont.woff application/octet-stream
upload fonts/fontawesome-webfont.woff2 application/octet-stream
