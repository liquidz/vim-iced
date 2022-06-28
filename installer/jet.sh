#!/bin/bash

set -e

version='0.2.18'
file='jet.zip'
if [ "$(uname)" == 'Darwin' ]; then
    os='macos'
else
    os='linux'
fi
url="https://github.com/borkdude/jet/releases/download/v${version}/jet-${version}-${os}-amd64.zip"

curl -L -o ${file} ${url} && unzip ${file} && rm -f ${file}
