(ns iced.core
  (:require
   [clojure.edn :as edn]
   [clojure.java.io :as io]
   [clojure.set :as set]
   [clojure.string :as str]
   [clojure.tools.cli :as cli]
   [clojure.walk :as walk]))

(def ^:private project-priority
  [:leiningen :boot :clojure-cli])

(def ^:private project->file-map
  {:leiningen "project.clj"
   :boot "build.boot"
   :clojure-cli "deps.edn"
   :shadow-cljs "shadow-cljs.edn"})

(def ^:private file->project-map
  (reduce-kv #(assoc %1 %3 %2) {} project->file-map))

(def cli-options
  [
   [nil "--with-kaocha" :id :kaocha]
   [nil "--with-cljs" :id :cljs]
   [nil "--without-cljs"]
   [nil "--dependency=DEPENDENCY" :default [] :assoc-fn #(update %1 %2 conj %3)]
   [nil "--middleware=MIDDLEWARE" :default [] :assoc-fn #(update %1 %2 conj %3)]
   [nil "--force-boot"]
   [nil "--force-clojure-cli"]
   [nil "--instant"]
   ["-h" "--help"]
   ])

(defn deps-edn [iced-root]
  (-> (str iced-root "/deps.edn")
      slurp
      edn/read-string))

(defn- dependency-str->deps
  [s]
  (let [[k v] (str/split s #":" 2)]
    {(symbol k) {:mvn/version v}}))

(defn detect-project-types
  [cwd]
  (loop [dir (io/file cwd)
         result {}]
    (if-not dir
      result
      (let [result (reduce
                    (fn [acc config-file]
                      (if (.exists (io/file dir config-file))
                        (merge (hash-map (get file->project-map config-file) dir)
                               ;; Precede the first one to be found
                               acc)
                        acc))
                    result
                    (keys file->project-map))]
        (recur (.getParentFile dir) result)))))

(defn- fetch-flaged-configs
  [config options]
  (for [[op _] options
        :when (contains? (:aliases config) op)]
    (get-in config [:aliases op])))

(defn fetch-dependencies-and-middlewares
  [config options]
  (let [flaged-configs (fetch-flaged-configs config options)
        dependencies (->> (:dependency options)
                          (map dependency-str->deps)
                          (reduce merge))
        dependencies (reduce (fn [res deps] (merge deps res))
                             dependencies
                             (map :extra-deps flaged-configs))]
    {:dependencies (merge (:deps config) dependencies)
     :middlewares (concat (:__middlewares__ config)
                          (mapcat :__middlewares__ flaged-configs)
                          (:middleware options))}))

(defn parse-options
  [cwd options]
  (let [detected (if (:instant options)
                   {:clojure-cli (io/file cwd)}
                   (detect-project-types cwd))
        detected (cond-> detected
                   (:force-boot options) (dissoc :leiningen :clojure-cli)
                   (:force-clojure-cli options) (dissoc :leiningen :boot))

        [project-type project-dir] (some #(when-let [project-dir (get detected %)]
                                            [% project-dir]) project-priority)
        project-file (io/file project-dir (get project->file-map project-type))

        ; options (cond-> options
        ;           (and (not (:without-cljs options))))
        ]
    project-file

    ))

(defn -repl
  [{:keys [iced-root cwd options arguments]}]
  (let [config (deps-edn iced-root)
        ; [project-type project-dir-file] (if (:instant options)
        ;                                   :clojure-cli
        ;                                   (detect-project-type cwd))
        deps-mdws (fetch-dependencies-and-middlewares config options)]
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
           "--dependency=foo:0.4.3"
           "--dependency=bar:0.4.3"
           "--middleware=iced.nrepl/wrap-iced"
           "--middleware=iced.nrepl/wrap-iced2"))
