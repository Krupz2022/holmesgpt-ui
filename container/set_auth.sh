#!/usr/bin/env bash

# Path to your JS file
JS_FILE="/usr/share/nginx/html/app.js"

# If USE_OAUTH is set, flip USE_OAUTH to true
if [ -n "$USE_OAUTH" ]; then
  sed -i 's/const USE_OAUTH = false;/const USE_OAUTH = true;/' "$JS_FILE"
fi

# If LOCAL_AUTH is true, replace validUser and validPass
if [ "$LOCAL_AUTH" = "true" ]; then
  if [ -n "$LOCAL_AUTH_USER" ]; then
    sed -i "s/const validUser = \".*\";/const validUser = \"$LOCAL_AUTH_USER\";/" "$JS_FILE"
  fi
  if [ -n "$LOCAL_AUTH_PASS" ]; then
    sed -i "s/const validPass = \".*\";/const validPass = \"$LOCAL_AUTH_PASS\";/" "$JS_FILE"
  fi
fi
