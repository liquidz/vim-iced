#!/bin/bash

set -e

version='0.0.10'
zip_file='jet.zip'
if [ "$(uname)" == 'Darwin' ]; then
    url="https://github.com/borkdude/jet/releases/download/v${version}/jet-${version}-macos-amd64.zip"
else
    url="https://github.com/borkdude/jet/releases/download/v${version}/jet-${version}-linux-amd64.zip"
fi

curl -L -o ${zip_file} ${url} && unzip ${zip_file} && rm -f ${zip_file}
