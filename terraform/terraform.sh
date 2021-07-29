#!/usr/bin/env bash

set -e
set -o pipefail

RED='\033[0;31m'
NOCOLOR='\033[0m'

if [[ $GOOGLE_APPLICATION_CREDENTIALS_BASE64 ]]; then
    tmpDir=$(mktemp -d -t tmp.XXXXXXXXXX)
    echo "$GOOGLE_APPLICATION_CREDENTIALS_BASE64" | base64 -d >$tmpDir/credentials.json
    export GOOGLE_APPLICATION_CREDENTIALS=$tmpDir/credentials.json
fi

tf_action=$@
if [ $# -eq 0 ]; then
    tf_action=plan
fi

terraform $tf_action