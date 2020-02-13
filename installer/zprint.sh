#!/bin/bash

set -e

version='0.5.3'
file='zprint'
if [ "$(uname)" == 'Darwin' ]; then
    os='m'
else
    os='l'
fi
url="https://github.com/kkinnear/zprint/releases/download/${version}/zprint${os}-${version}"

curl -L -o ${file} ${url} && chmod +x ${file}
