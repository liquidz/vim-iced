(ns iced-jackin
  (:require [clojure.java.io :as io]
            [clojure.string :as str]
            iced-repl
            [org.panchromatic.mokuhan :as mokuhan]))

(def ^:private dependencies
  (let [deps (-> "deps.edn" slurp read-string :deps)]
    (reduce (fn [res [name {:mvn/keys [version]}]]
              (assoc res name version))
            {} deps)))

(defn- leiningen-params []
  (let [dep-fmt (fn [[name version]] (format "update-in :dependencies conj '[%s \"%s\"]'" name version))
        mdw-fmt #(format "update-in :repl-options:nrepl-middleware conj '%s'" %)]
    (->> (concat (map dep-fmt dependencies)
                 (map mdw-fmt iced-repl/middlewares))
         (str/join " -- "))))

(defn- boot-params []
  (let [dep-fmt (fn [[name version]] (format "-d %s:%s" name version))
        mdw-fmt #(format "-m %s" %)]
    (->> (concat ["-i \"(require 'cider.tasks)\""]
                 (map dep-fmt dependencies)
                 ["-- cider.tasks/add-middleware"]
                 (map mdw-fmt iced-repl/middlewares))
         (str/join " "))))

(defn -main []
  (let [file (io/file "bin/iced")]
    (->> {:leiningen-params (leiningen-params)
          :boot-params (boot-params)}
         (mokuhan/render (slurp "clj/template/iced.bash"))
         (spit file))
    (.setExecutable file true)
    (System/exit 0)))

