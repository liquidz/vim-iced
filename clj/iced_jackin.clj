(ns iced-jackin
  (:require [clojure.java.io :as io]
            [clojure.string :as str]
            iced-repl
            [org.panchromatic.mokuhan :as mokuhan]))

(def ^:private config
  (-> "deps.edn" slurp read-string))

(defn- deps->map [deps]
  (reduce (fn [res [name {:mvn/keys [version]}]]
            (assoc res name version))
          {} deps))

(def ^:private clj-dependencies
  (deps->map (:deps config)))

(def ^:private cljs-dependencies
  (deps->map (get-in config [:aliases :icedcljs :extra-deps])))

(defn- leiningen-params [dependencies middlewares]
  (let [dep-fmt (fn [[name version]] (format "update-in :dependencies conj '[%s \"%s\"]'" name version))
        mdw-fmt #(format "update-in :repl-options:nrepl-middleware conj '%s'" %)]
    (->> (concat (map dep-fmt dependencies)
                 (map mdw-fmt middlewares))
         (str/join " -- "))))

(defn- boot-params [dependencies middlewares]
  (let [dep-fmt (fn [[name version]] (format "-d %s:%s" name version))
        mdw-fmt #(format "-m %s" %)]
    (->> (concat ["-i \"(require 'cider.tasks)\""]
                 (map dep-fmt dependencies)
                 ["-- cider.tasks/add-middleware"]
                 (map mdw-fmt middlewares))
         (str/join " "))))

(defn- cli-extra-deps [dependencies]
  (->> dependencies
       (map (fn [[name version]]
              (format "%s {:mvn/version \\\"%s\\\"}" name version)))
       (str/join " ")))

(defn -main []
  (let [file (io/file "bin/iced")
        clj-deps clj-dependencies
        cljs-deps (merge clj-dependencies cljs-dependencies)]
    (->> {:leiningen-params (leiningen-params clj-deps iced-repl/clj-middlewares)
          :leiningen-cljs-params (leiningen-params cljs-deps iced-repl/cljs-middlewares)
          :boot-params (boot-params clj-deps iced-repl/clj-middlewares)
          :boot-cljs-params (boot-params cljs-deps iced-repl/cljs-middlewares)
          :cli-cljs-extra-deps (cli-extra-deps cljs-dependencies)}
         (mokuhan/render (slurp "clj/template/iced.bash"))
         (spit file))
    (.setExecutable file true)
    (System/exit 0)))

