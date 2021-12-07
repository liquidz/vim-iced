#!/bin/bash

set -e

version='0.1.0'
file='jet.zip'
if [ "$(uname)" == 'Darwin' ]; then
    os='macos'
else
    os='linux'
fi
url="https://github.com/borkdude/jet/releases/download/v${version}/jet-${version}-${os}-amd64.zip"

curl -L -o ${file} ${url} && unzip ${file} && rm -f ${file}
