(ns iced.core
  (:require
   [clojure.edn :as edn]
   [clojure.java.io :as io]
   [clojure.set :as set]
   [clojure.string :as str]
   [clojure.tools.cli :as cli]
   [clojure.walk :as walk]))

(def cli-options
  [
   [nil "--with-kaocha" :id :kaocha]
   [nil "--with-cljs" :id :cljs]
   [nil "--without-cljs"]
   [nil "--dependency" :default [] :update-fn conj]
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


(comment
  (let [deps (deps-edn +iced-root+)
        base-deps (:deps deps)]

    base-deps
    )
  )

(defn- fetch-extra-configs
  [config options]
  (for [[op _] options
        :when (contains? (:aliases config) op)]
    (get-in config [:aliases op])))

(defn -repl
  [{:keys [iced-root cwd options arguments]}]
  (let [config (deps-edn iced-root)
        [project-type project-dir-file] (if (:instant options)
                                          :clojure-cli
                                          (detect-project-type cwd))
        extra-configs (fetch-extra-configs config options)
        ; options (set/rename-keys options {:with-kaocha :kaocha
        ;                                   :with-cljs :cljs})
        ]
    (println project-type
             options
             (extract-configs config options))
    ; (case project-type
    ;   :leiningen (str "LEIN" project-dir-file)
    ;   :boot (str "BOOT" project-dir-file)
    ;   :clojure-cli (str "CLI" project-dir-file)
    ;   (throw (ex-info "Failed to detect clojure project" {:cwd cwd}))
    ;   )
    ))

(defn -main [cwd iced-root & args]
  (let [{:keys [options arguments summary errors]} (cli/parse-opts args cli-options)
        [subcommand & arguments] arguments]
    (case subcommand
      "repl" (-repl {:iced-root iced-root :cwd cwd :options options :arguments arguments})
      "help" (println "FIXME help")
      "version" (println "FIXME version"))))

(comment
  (def +merr-dir+ "/Users/iizuka/src/github.com/liquidz/merr")
  (def +iced-root+ "/Users/iizuka/src/github.com/liquidz/vim-iced")
    (-main +merr-dir+ +iced-root+ "repl" "--with-kaocha"
           "--dependency foo:0.4.3"
           "--dependency bar:0.4.3"
           )
  )
