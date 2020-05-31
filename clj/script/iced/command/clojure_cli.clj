(ns iced.command.clojure-cli
  (:require
   [clojure.string :as str]))

(defn dependencies->args
  [iced-root deps]
  ["-Sdeps"
   (str "'{:deps {"
        (->> deps
             (map (fn [[k v]] (format "%s %s" k (pr-str v))))
             (cons (format "iced-repl {:local/root \"%s\"}" iced-root))
             (str/join " "))
        " }}'")])

(defn middlewares->args
  [mdws]
  ["-m" (str "'[" (str/join " " (map pr-str mdws)) " ]'")])

(defn construct-command
  "Return command list like [\"foo\" \"-option\" \"value\"]."
  [{:keys [dependencies middlewares]} args iced-root]
  (flatten
   (concat
    [(or (System/getenv "ICED_REPL_CLOJURE_CLI_CMD") "clj")]
    args
    (dependencies->args iced-root dependencies)
    ["-m" "nrepl.cmdline"]
    (middlewares->args middlewares)
    ["--interactive"])))
