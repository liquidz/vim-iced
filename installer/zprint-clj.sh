#!/bin/bash

set -e

version='1.2.8'
# NOTE: macOS has a same named command, so add '-clj' postfix
file='zprint-clj'
if [ "$(uname)" == 'Darwin' ]; then
    os='m'
else
    os='l'
fi
url="https://github.com/kkinnear/zprint/releases/download/${version}/zprint${os}-${version}"

curl -L -o ${file} ${url} && chmod +x ${file}
