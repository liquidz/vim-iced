#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
VERSION=$(grep 'Version: ' ${SCRIPT_DIR}/../doc/vim-iced.txt | cut -d' ' -f2)

### vim-iced verion
VERSION_NUM=''
for n in $(echo ${VERSION} | tr '.' '\n'); do
    VERSION_NUM="${VERSION_NUM}$(printf %02d ${n})"
done
VERSION_NUM=$(echo $VERSION_NUM | sed -e 's/^0*//g')

grep "g:vim_iced_version = ${VERSION_NUM}" ${SCRIPT_DIR}/../ftplugin/clojure.vim
if [ $? -ne 0 ]; then
    echo "version_check: Version num in ftplugin/clojure.vim is outdated (${VERSION_NUM})"
    exit 1
fi

grep "== ${VERSION}" ${SCRIPT_DIR}/../CHANGELOG.adoc
if [ $? -ne 0 ]; then
    echo 'version_check: There is no corresponding section in CHANGELOG'
    exit 1
fi

### borkdude/jet version
JET_URL='https://github.com/borkdude/jet/releases.atom'
JET_VERSION=$(curl -s ${JET_URL} | grep '<title>' | head -n 2 | tail -n 1 | sed 's/[^0-9.]//g')
grep "version='${JET_VERSION}'" ${SCRIPT_DIR}/../installer/jet.sh
if [ $? -ne 0 ]; then
    echo "version_check: Version num in installer/jet.sh is outdated (${JET_VERSION})"
    exit 1
fi

### greglook/cljstyle version
CLJSTYLE_URL='https://github.com/greglook/cljstyle/releases.atom'
CLJSTYLE_VERSION=$(curl -s ${CLJSTYLE_URL} | grep '<title>' | head -n 2 | tail -n 1 | sed 's/[^0-9.]//g')
grep "version='${CLJSTYLE_VERSION}'" ${SCRIPT_DIR}/../installer/cljstyle.sh
if [ $? -ne 0 ]; then
    echo "version_check: Version num in installer/cljstyle.sh is outdated (${CLJSTYLE_VERSION})"
    exit 1
fi

### kkinnear/zprint version
ZPRINT_URL='https://github.com/kkinnear/zprint/releases.atom'
ZPRINT_VERSION=$(curl -s ${ZPRINT_URL} | grep '<title>' | head -n 2 | tail -n 1 | sed 's/[^0-9.]//g')
grep "version='${ZPRINT_VERSION}'" ${SCRIPT_DIR}/../installer/zprint.sh
if [ $? -ne 0 ]; then
    echo "version_check: Version num in installer/zprint.sh is outdated (${ZPRINT_VERSION})"
    exit 1
fi
