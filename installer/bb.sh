#!/bin/bash

set -e

INSTALLER=./.bb_install

curl -sL -o ${INSTALLER} https://raw.githubusercontent.com/babashka/babashka/master/install
chmod +x ${INSTALLER}
${INSTALLER} --dir $(pwd)
\rm -f ${INSTALLER}
