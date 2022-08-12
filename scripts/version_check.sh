#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)

### borkdude/jet version
echo "CHECKING: borkdude/jet"
JET_URL='https://github.com/borkdude/jet/releases.atom'
JET_VERSION=$(curl -s ${JET_URL} | grep '<title>' | head -n 2 | tail -n 1 | sed 's/[^0-9.]//g')
grep "version='${JET_VERSION}'" ${SCRIPT_DIR}/../installer/jet.sh
if [ $? -ne 0 ]; then
    echo "version_check: Version num in installer/jet.sh is outdated (${JET_VERSION})"
    exit 1
fi

### greglook/cljstyle version
echo "CHECKING: greglook/cljstyle"
CLJSTYLE_URL='https://github.com/greglook/cljstyle/releases.atom'
CLJSTYLE_VERSION=$(curl -s ${CLJSTYLE_URL} | grep '<title>' | head -n 2 | tail -n 1 | sed 's/[^0-9.]//g')
grep "version='${CLJSTYLE_VERSION}'" ${SCRIPT_DIR}/../installer/cljstyle.sh
if [ $? -ne 0 ]; then
    echo "version_check: Version num in installer/cljstyle.sh is outdated (${CLJSTYLE_VERSION})"
    exit 1
fi

### kkinnear/zprint version
echo "CHECKING: kkinnear/zprint"
ZPRINT_URL='https://github.com/kkinnear/zprint/releases.atom'
ZPRINT_VERSION=$(curl -s ${ZPRINT_URL} | grep '<title>' | head -n 2 | tail -n 1 | sed 's/[^0-9.]//g')
grep "version='${ZPRINT_VERSION}'" ${SCRIPT_DIR}/../installer/zprint-clj.sh
if [ $? -ne 0 ]; then
    echo "version_check: Version num in installer/zprint-clj.sh is outdated (${ZPRINT_VERSION})"
    exit 1
fi

### candid82/joker version
echo "CHECKING: candid82/joker"
JOKER_URL='https://github.com/candid82/joker/releases.atom'
JOKER_VERSION=$(curl -s ${JOKER_URL} | grep '<title>' | head -n 2 | tail -n 1 | sed 's/[^0-9.]//g')
grep "version='${JOKER_VERSION}'" ${SCRIPT_DIR}/../installer/joker.sh
if [ $? -ne 0 ]; then
    echo "version_check: Version num in installer/joker.sh is outdated (${JOKER_VERSION})"
    exit 1
fi
