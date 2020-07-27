(ns test-runner
  (:require
   [clojure.test :as t]))

(def ^:private test-ns-list
  '(shadow-cljs-validation-test
    lein-is-using-cljs-test
    deps-is-using-cljs-test))

(doseq [sym test-ns-list]
  (require sym))

(let [{:keys [:fail :error]} (apply t/run-tests test-ns-list)]
  (System/exit (+ fail error)))
