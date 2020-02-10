#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
VERSION=$(grep 'Version: ' ${SCRIPT_DIR}/../doc/vim-iced.txt | cut -d' ' -f2)

VERSION_NUM=''
for n in $(echo ${VERSION} | tr '.' '\n'); do
    VERSION_NUM="${VERSION_NUM}$(printf %02d ${n})"
done
VERSION_NUM=$(echo $VERSION_NUM | sed -e 's/^0*//g')

grep "g:vim_iced_version = ${VERSION_NUM}" ${SCRIPT_DIR}/../ftplugin/clojure.vim
if [ $? -ne 0 ]; then
    echo 'version_check: Version num in ftplugin/clojure.vim is outdated'
    exit 1
fi

grep "== ${VERSION}" ${SCRIPT_DIR}/../CHANGELOG.adoc
if [ $? -ne 0 ]; then
    echo 'version_check: There is no corresponding section in CHANGELOG'
    exit 1
fi
