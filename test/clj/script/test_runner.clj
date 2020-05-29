(ns test-runner
  (:require
   [clojure.test :as t]))

(def ^:private test-ns-list
  '(
    iced.command.core-test
    iced.command.leiningen-test
    iced.command.boot-test
    shadow-cljs-validation-test
    ))

(doseq [sym test-ns-list]
  (require sym))

(let [{:keys [:fail :error]} (apply t/run-tests test-ns-list)]
  (System/exit (+ fail error)))
