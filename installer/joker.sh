#!/bin/bash

set -e

version='0.15.7'
file='joker.zip'
if [ "$(uname)" == 'Darwin' ]; then
    os='mac'
else
    os='linux'
fi
url="https://github.com/candid82/joker/releases/download/v${version}/joker-${version}-${os}-amd64.zip"

curl -L -o ${file} ${url} && unzip ${file} && rm -f ${file}
