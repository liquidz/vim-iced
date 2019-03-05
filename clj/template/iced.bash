#!/bin/bash

CWD=$(pwd)
SCRIPT_DIR=$(cd $(dirname $0); pwd)
PROJECT_DIR=$(cd $SCRIPT_DIR; cd ..; pwd)
VERSION=$(grep 'Version: ' ${SCRIPT_DIR}/../doc/vim-iced.txt | cut -d' ' -f2)

IS_LEININGEN=0
IS_BOOT=0
IS_CLOJURE_CLI=0
IS_SHADOW_CLJS=0

function iced_usage() {
    echo "vim-iced ${VERSION}"
    echo ""
    echo "Usage:"
    echo "  iced <task> [options]"
    echo ""
    echo "Following tasks are available:"
    echo "  repl      Start repl"
    echo "  help      Print this help"
    echo "  version   Print vim-iced version"
    echo ""
    echo "Use 'iced help <task>' or 'iced <task> --help' for more information."
    exit 1
}

function iced_repl_usage() {
    echo "Usage:"
    echo "  iced repl [options] [--with-cljs] [--force-boot] [--force-clojure-cli]"
    echo ""
    echo "Start repl. Leiningen, Boot, and Clojure CLI are supported."
    echo ""
    echo "The --with-cljs option enables ClojureScript features."
    echo "This option is enabled automatically when project configuration"
    echo "file(eg. project.clj) contains 'org.clojure/clojurescript' dependency."
    echo ""
    echo "The --force-boot and --force-clojure-cli option enable you to start specified repl."
    echo ""
    echo "Other options are passed to each programs."
    echo "To specify Leiningen profile:"
    echo "  $ iced repl with-profile +foo"
    echo "To specify Clojure CLI alias:"
    echo "  $ iced repl -A:foo"
    echo "Combinating several options:"
    echo "  $ iced repl --with-cljs --force-clojure-cli -A:foo"
}

function echo_info() {
    echo -e "\e[32mOK\e[m: \e[1m${1}\e[m"
}

function echo_error() {
    echo -e "\e[31mNG\e[m: \e[1m${1}\e[m"
}

if [ $# -lt 1 ]; then
    iced_usage
    exit 1
fi

ARGV=($@)
ARGV=("${ARGV[@]:1}")

IS_HELP=0
IS_CLJS=0
FORCE_BOOT=0
FORCE_CLOJURE_CLI=0

OPTIONS=""
for x in ${ARGV[@]}; do
    if [ $x = '--help' ]; then
        IS_HELP=1
    elif [ $x = '--with-cljs' ]; then
        IS_CLJS=1
    elif [ $x = '--force-boot' ]; then
        FORCE_BOOT=1
    elif [ $x = '--force-clojure-cli' ]; then
        FORCE_CLOJURE_CLI=1
    else
        OPTIONS="${OPTIONS} ${x}"
    fi
done

IS_DETECTED=0
while :
do
    ls project.clj > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        IS_LEININGEN=1
        IS_DETECTED=1

        grep org.clojure/clojurescript project.clj > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            IS_CLJS=1
        fi
    fi

    ls build.boot > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        IS_BOOT=1
        IS_DETECTED=1

        grep org.clojure/clojurescript build.boot > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            IS_CLJS=1
        fi
    fi

    ls deps.edn > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        IS_CLOJURE_CLI=1
        IS_DETECTED=1

        grep org.clojure/clojurescript deps.edn > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            IS_CLJS=1
        fi
    fi

    ls shadow-cljs.edn > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        IS_SHADOW_CLJS=1
        IS_DETECTED=1
    fi

    if [ $IS_DETECTED -eq 1 ]; then
        break
    fi

    cd ..
    if [ $(pwd) == $CWD ]; then
        break
    else
        CWD=$(pwd)
    fi
done

if [ $FORCE_BOOT -eq 1 ]; then
    IS_LEININGEN=0
    IS_CLOJURE_CLI=0
elif [ $FORCE_CLOJURE_CLI -eq 1 ]; then
    IS_LEININGEN=0
    IS_BOOT=0
fi

case "$1" in
    "repl")
        if [ $IS_HELP -eq 1 ]; then
            iced_repl_usage
        elif [ $IS_LEININGEN -eq 1 ]; then
            echo_info "Leiningen project is detected"
            if [ $IS_CLJS -eq 0 ]; then
                lein {{{leiningen-params}}} -- $OPTIONS repl
            else
                lein {{{leiningen-cljs-params}}} -- $OPTIONS repl
            fi
        elif [ $IS_BOOT -eq 1 ]; then
            echo_info "Boot project is detected"
            if [ $IS_CLJS -eq 0 ]; then
                boot {{{boot-params}}} -- $OPTIONS repl
            else
                boot {{{boot-cljs-params}}} -- $OPTIONS repl
            fi
        elif [ $IS_CLOJURE_CLI -eq 1 ]; then
            echo_info "Clojure CLI project is detected"
            if [ $IS_CLJS -eq 0 ]; then
                clojure $OPTIONS -Sdeps "{:deps {iced-repl {:local/root \"${PROJECT_DIR}\"}}}" -m iced-repl
            else
                clojure $OPTIONS -Sdeps "{:deps {iced-repl {:local/root \"${PROJECT_DIR}\"} {{{cli-cljs-extra-deps}}}}}" \
                    -m iced-repl 'with-cljs-middleware'
            fi
        elif [ $IS_SHADOW_CLJS -eq 1 ]; then
            echo_error 'Currently iced command does not support shadow-cljs.'
            echo 'Please see `:h vim-iced-manual-shadow-cljs` for manual setting up.'
            exit 1
        else
            echo_error 'Failed to detect clojure project'
            exit 1
        fi
        ;;
    "help")
        case "$2" in
            "repl")
                iced_repl_usage
                ;;
            *)
                iced_usage
                ;;
        esac
        exit 0
        ;;
    "version")
        echo "${VERSION}"
        ;;
    *)
        iced_usage
        exit 1
        ;;
esac

exit 0
