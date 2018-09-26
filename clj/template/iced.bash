#!/bin/bash

CWD=$(pwd)
SCRIPT_DIR=$(cd $(dirname $0); pwd)
PROJECT_DIR=$(cd $SCRIPT_DIR; cd ..; pwd)
VERSION=$(grep 'Version: ' ${SCRIPT_DIR}/../doc/vim-iced.txt | cut -d' ' -f2)

IS_LEININGEN=0
IS_BOOT=0
IS_CLOJURE_CLI=0

function iced_usage() {
    echo "vim-iced ${VERSION}"
    echo ""
    echo "Following tasks are available:"
    echo "  repl    Start repl"
    echo "  help    Print this help"
    exit 1
}

if [ $# -lt 1 ]; then
    iced_usage
    exit 1
fi

ARGV=($@)
ARGV=("${ARGV[@]:1}")
OPTIONS=""
for x in ${ARGV[@]}; do
  OPTIONS="${OPTIONS} ${x}"
done

while :
do
    ls project.clj > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        IS_LEININGEN=1
        break
    fi

    ls build.boot > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        IS_BOOT=1
        break
    fi

    ls deps.edn > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        IS_CLOJURE_CLI=1
        break
    fi

    cd ..
    if [ $(pwd) == $CWD ]; then
        break
    else
        CWD=$(pwd)
    fi
done

case "$1" in
    "repl")
        if [ $IS_LEININGEN -eq 1 ];then
            echo "Leiningen project is detected."
            {{{leiningen}}}
        elif [ $IS_BOOT -eq 1 ]; then
            echo "Boot project is detected."
            {{{boot}}}
        elif [ $IS_CLOJURE_CLI -eq 1 ]; then
            echo "Clojure CLI project is detected."
            clojure $OPTIONS -Sdeps "{:deps {iced-repl {:local/root \"${PROJECT_DIR}\"}}}" -m iced-repl
        else
            echo 'Failed to detect clojure project.'
            exit 1
        fi
        ;;
    "help")
        iced_usage
        exit 0
        ;;
    *)
        iced_usage
        exit 1
        ;;
esac

exit 0
