(ns iced-repl
  (:require [nrepl.cmdline :as cmd]))

(defn -main [& args]
  (->> "deps.edn"
       slurp
       read-string
       :__middlewares__
       pr-str
       (cmd/-main "-m")))
