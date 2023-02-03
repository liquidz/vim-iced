#!/bin/bash

set -e

version='0.4.23'
file='jet.tar.gz'
if [ "$(uname)" == 'Darwin' ]; then
    os='macos'
else
    os='linux'
fi
url="https://github.com/borkdude/jet/releases/download/v${version}/jet-${version}-${os}-amd64.tar.gz"

curl -L -o ${file} ${url} && tar xvf ${file} && rm -f ${file}
