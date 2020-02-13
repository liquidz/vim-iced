#!/bin/bash

set -e

version='0.12.0'
file='cljstyle.tar.gz'
if [ "$(uname)" == 'Darwin' ]; then
    os='macos'
else
    os='linux'
fi
url="https://github.com/greglook/cljstyle/releases/download/${version}/cljstyle_${version}_${os}.tar.gz"

curl -L -o ${file} ${url} && tar xvf ${file} && rm -f ${file}
