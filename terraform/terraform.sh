#!/usr/bin/env bash

set -e

tmpDir=$(mktemp -d -t tmp.XXXXXXXXXX)
echo "$GOOGLE_APPLICATION_CREDENTIALS_BASE64" | base64 -d >$tmpDir/credentials.json
export GOOGLE_APPLICATION_CREDENTIALS=$tmpDir/credentials.json

tf_action=$@
if [ $# -eq 0 ]; then
    tf_action=plan
fi

terrafrom $tf_action