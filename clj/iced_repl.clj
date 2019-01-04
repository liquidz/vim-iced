(ns iced-repl
  (:require [nrepl.cmdline :as cmd]))

(def clj-middlewares
  ["cider.nrepl/wrap-classpath"
   "cider.nrepl/wrap-complete"
   "cider.nrepl/wrap-debug"
   "cider.nrepl/wrap-format"
   "cider.nrepl/wrap-info"
   "cider.nrepl/wrap-macroexpand"
   "cider.nrepl/wrap-ns"
   "cider.nrepl/wrap-out"
   "cider.nrepl/wrap-pprint"
   "cider.nrepl/wrap-pprint-fn"
   "cider.nrepl/wrap-spec"
   "cider.nrepl/wrap-test"
   "cider.nrepl/wrap-trace"
   "cider.nrepl/wrap-undef"
   "refactor-nrepl.middleware/wrap-refactor"
   "iced.nrepl/wrap-iced"])

(def cljs-middlewares
  (conj clj-middlewares "cider.piggieback/wrap-cljs-repl"))

(defn -main [& args]
  (if (= "with-cljs-middleware" (some-> args seq first))
    (cmd/-main "-m" (pr-str cljs-middlewares))
    (cmd/-main "-m" (pr-str clj-middlewares))))
