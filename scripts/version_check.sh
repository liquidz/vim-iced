#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
VERSION=$(grep 'Version: ' ${SCRIPT_DIR}/../doc/vim-iced.txt | cut -d' ' -f2)

VERSION_NUM=''
for n in $(echo ${VERSION} | tr '.' '\n'); do
    VERSION_NUM="${VERSION_NUM}$(printf %02d ${n})"
done
VERSION_NUM=$(echo $VERSION_NUM | sed -e 's/^0*//g')

grep "g:vim_iced_version = ${VERSION_NUM}" ${SCRIPT_DIR}/../ftplugin/clojure.vim
