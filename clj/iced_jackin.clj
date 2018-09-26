(ns iced-jackin
  (:require [clojure.java.io :as io]
            [clojure.string :as str]
            iced-repl
            [org.panchromatic.mokuhan :as mokuhan]))

(def ^:private dependencies
   (-> "deps.edn" slurp read-string :deps))

(defn- leiningen []
  (->>
   (concat
    (for [[name {:mvn/keys [version]}] dependencies]
      (format "update-in :dependencies conj '[%s \"%s\"]'" name version))
    (for [middleware iced-repl/middlewares]
      (format "update-in :repl-options:nrepl-middleware conj '%s'" middleware))
    ["repl"])
   (str/join " -- ")
   (str "lein ")))

(defn- boot []
  (->>
   (concat
    ["-i \"(require 'cider.tasks)\""]
    (for [[name {:mvn/keys [version]}] dependencies]
      (format "-d %s:%s" name version))
    ["-- cider.tasks/add-middleware"]
    (for [middleware iced-repl/middlewares]
      (format "-m %s" middleware))
    ["-- repl"])
   (str/join " ")
   (str "boot ")))

(defn -main []
  (let [file (io/file "bin/iced")]
    (->> {:leiningen (leiningen) :boot (boot)}
         (mokuhan/render (slurp "clj/template/iced.bash"))
         (spit file))
    (.setExecutable file true)
    (System/exit 0)))

