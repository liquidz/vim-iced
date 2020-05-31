OLD_CMD=iced
NEW_CMD=iced2
OPTIONS=("--" "--with-cljs" "--with-kaocha" "-A:dummy" "--dependency=kaocha-nrepl:0.1.1" "--middleware=kaocha-nrepl.core/wrap-kaocha")
DIRECTORIES=("leiningen" "boot" "clojure")

for OP in ${OPTIONS[@]}; do
    for DIR in ${DIRECTORIES[@]}; do
        OLD=$(cd test/resources/iced_command/${DIR}; ${OLD_CMD} repl ${OP} --dryrun | grep -v OK)
        NEW=$(cd test/resources/iced_command/${DIR}; ${NEW_CMD} repl ${OP} --dryrun | grep -v OK)
        if [ "${OLD}" = "${NEW}" ]; then
            echo "OK: ${DIR} [${OP}]"
        else
            echo "NG: ${DIR} [${OP}]"
            echo "${OLD}"
            echo "${NEW}"
            exit 1
        fi
    done
done

OLD=$(cd test/resources/iced_command/${DIR}; ICED_REPL_CLOJURE_CLI_CMD=dummy ${OLD_CMD} repl --dryrun | grep -v OK)
NEW=$(cd test/resources/iced_command/${DIR}; ICED_REPL_CLOJURE_CLI_CMD=dummy ${NEW_CMD} repl --dryrun | grep -v OK)
if [ "${OLD}" = "${NEW}" ]; then
    echo "OK: ICED_REPL_CLOJURE_CLI_CMD"
else
    echo "NG: ICED_REPL_CLOJURE_CLI_CMD"
    exit 1
fi

exit 0
