#!/bin/bash

set -e

version='0.16.626'
file='cljstyle.zip'
if [ "$(uname)" == 'Darwin' ]; then
    os='macos'
else
    os='linux'
fi
arch="$(uname -m)"
url="https://github.com/greglook/cljstyle/releases/download/${version}/cljstyle_${version}_${os}_${arch}.zip"

curl -L -o ${file} ${url} && unzip ${file} && rm -f ${file}
