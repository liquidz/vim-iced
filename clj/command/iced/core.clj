(ns iced.core
  (:require
   [clojure.edn :as edn]
   [clojure.java.io :as io]
   [clojure.string :as str]
   [clojure.tools.cli :as cli]
   [clojure.walk :as walk]))

(def cli-options
  [
   [nil "--with-kaocha"]
   [nil "--with-cljs"]
   [nil "--without-cljs"]
   [nil "--dependency"]
   [nil "--middleware"]
   [nil "--force-boot"]
   [nil "--force-clojure-cli"]
   [nil "--instant"]
   ["-h" "--help"]
   ])

(defn deps-edn [iced-root]
  (-> (str iced-root "/deps.edn")
      slurp
      edn/read-string))

(defn detect-project-type [cwd]
  (loop [dir (io/file cwd)]
    (when dir
      (condp #(.exists (io/file %2 %1)) dir
        "project.clj" [:leiningen dir]
        "build.boot" [:boot dir]
        "deps.edn" [:clojure-cli dir]
        (recur (.getParentFile dir))))))

(defn read-string [s]
  (-> (str "[ " s " ]")
      (str/replace "~" "")
      (str/replace "#\"" "\"")
      (str/replace "#=(" "(")
      edn/read-string))



(defn -repl [{:keys [iced-root cwd options arguments]}]
  (let [config (deps-edn iced-root)
        [project-type project-dir-file] (if (:instant options)
                                          :clojure-cli
                                          (detect-project-type cwd))]
    ; (case project-type
    ;   :leiningen (str "LEIN" project-dir-file)
    ;   :boot (str "BOOT" project-dir-file)
    ;   :clojure-cli (str "CLI" project-dir-file)
    ;   (throw (ex-info "Failed to detect clojure project" {:cwd cwd}))
    ;   )
    )
  )

(defn -main [cwd iced-root & args]
  (let [{:keys [options arguments summary errors]} (cli/parse-opts args cli-options)
        [subcommand & arguments] arguments]
    (println options)
    (println "----")
    (println arguments)
    (case subcommand
      "repl" (-repl {:iced-root iced-root :cwd cwd :options options :arguments arguments})
      "help" (println "FIXME help")
      "version" (println "FIXME version"))))

(comment
  (def +merr-dir+ "/Users/iizuka/src/github.com/liquidz/merr")
  (def +iced-root+ "/Users/iizuka/src/github.com/liquidz/vim-iced")
    (-main +merr-dir+ +iced-root+ "repl")
  )
