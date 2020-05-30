(ns iced.command.core
  (:require
   [clojure.edn :as edn]
   [clojure.java.io :as io]
   [clojure.string :as str]
   [clojure.tools.cli :as cli]
   [iced.command.boot :as i.c.boot]
   [iced.command.clojure-cli :as i.c.clj]
   [iced.command.leiningen :as i.c.lein]
   [iced.common.color :as color]
   [iced.common.process :as process]
   [iced.common.version :as version]))

(defn- print-info-log
  [s]
  (println (str (color/green "OK") ": " (color/bold s))))

(defn- print-error-log
  [s]
  (println (str (color/red "NG") ": " (color/bold s))))

(def ^:private base-help-text
  (str/trim "
vim-iced %s

Usage:
  iced <task> [options]

Following tasks are available:
  repl      Start repl
  help      Print this help
  version   Print vim-iced version

Use 'iced help <task>' or 'iced <task> --help' for more information.
  "))

(def ^:private project-priority
  "Left side has high priority"
  [:leiningen :boot :clojure-cli])

(def ^:private project->file-map
  {:leiningen "project.clj"
   :boot "build.boot"
   :clojure-cli "deps.edn"
   :shadow-cljs "shadow-cljs.edn"})

(def ^:private project-name-map
  {:leiningen "Leiningen"
   :boot "Boot"
   :clojure-cli "Clojure CLI"
   :shadow-cljs "Shadow-cljs"})

(def ^:private file->project-map
  (reduce-kv #(assoc %1 %3 %2) {} project->file-map))

(def cli-options
  [[nil "--with-kaocha" :id :kaocha]
   [nil "--with-cljs" "Enables ClojureScript features" :id :cljs]
   [nil "--without-cljs"]
   [nil "--dependency=DEPENDENCY" :default [] :assoc-fn #(update %1 %2 conj %3)]
   [nil "--middleware=MIDDLEWARE" :default [] :assoc-fn #(update %1 %2 conj %3)]
   [nil "--force-boot"]
   [nil "--force-clojure-cli"]
   [nil "--instant"]
   [nil "--dryrun"]
   ["-h" "--help"]])

(def option-names
  (->> cli-options
       (mapcat (juxt first second))
       (remove nil?)
       (map #(if-let [i (str/index-of % "=")]
               (subs % 0 i)
               %))))

(defn- iced-option?
  "Return true if the specified option is a vim-iced's one."
  [s]
  (some #(str/starts-with? s %) option-names))

(defn iced-deps-edn
  [iced-root]
  (-> (str iced-root "/deps.edn")
      slurp
      edn/read-string))

(defn- dependency-str->deps
  [s]
  (let [[k v] (str/split s #":" 2)]
    {(symbol k) {:mvn/version v}}))

(defn- detect-project-types*
  "Detect all project types from current working directory.
  Returns a map like below.
  {:leiningen project-root-dir, :boot project-root-dir, ...}"
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

(defn- detect-project
  [cwd options]
  (let [detected-project (if (:instant options)
                           {:clojure-cli (io/file cwd)}
                           (detect-project-types* cwd))
        detected-project (cond-> detected-project
                           (:force-boot options) (dissoc :leiningen :clojure-cli)
                           (:force-clojure-cli options) (dissoc :leiningen :boot))
        ;; select project by defined priorities
        [project-type project-dir] (some #(when-let [project-dir (get detected-project %)]
                                            [% project-dir])
                                         project-priority)

        project-file (some-> project-dir (io/file (get project->file-map project-type)))]
    {:project-type project-type
     :project-file project-file}))

(defn- cljs-auto-detected?
  [options project-type project-file]
  (some?  (and (= :leiningen project-type)
               (not (:without-cljs options))
               (not (:cljs options))
               (i.c.lein/using-cljs? (slurp project-file)))))

(defn- print-detected-project
  [project-type options]
  (let [project-name (get project-name-map project-type)]
    (cond
      (and project-name (:instant options))
      (print-info-log "Starting instant REPL via Clojure CLI")

      (and (not= :shadow-cljs project-type) project-name)
      (print-info-log (str project-name " project is detected."))

      :else nil)))

(defn- fetch-flaged-configs
  "Fetch configs for flags such as `with-cljs`, `with-kaocha`, and so on."
  [iced-config options]
  (for [[op _] options
        :when (contains? (:aliases iced-config) op)]
    (do (print-info-log (str (str/upper-case (name op)) " option is enabled."))
        (get-in iced-config [:aliases op]))))

(defn fetch-dependencies-and-middlewares
  "Fetch dependent libraries and middleware according to specified options."
  [iced-config options]
  (let [flaged-configs (fetch-flaged-configs iced-config options)
        dependencies (->> (:dependency options)
                          (map dependency-str->deps)
                          (reduce merge))
        dependencies (reduce (fn [res deps] (merge deps res))
                             dependencies
                             (map :extra-deps flaged-configs))]
    {:dependencies (merge (:deps iced-config) dependencies)
     :middlewares (concat (:__middlewares__ iced-config)
                          (mapcat :__middlewares__ flaged-configs)
                          (:middleware options))}))

(defn -repl-start
  [iced-root cwd options arguments]
  (let [iced-config (iced-deps-edn iced-root)
        {:keys [project-type project-file]} (detect-project cwd options)
        options (cond-> options
                  (cljs-auto-detected? options project-type project-file)
                  (assoc :cljs true))
        _ (print-detected-project project-type options)
        deps-mdws (fetch-dependencies-and-middlewares iced-config options)
        command (case project-type
                  :leiningen (i.c.lein/construct-command deps-mdws arguments)
                  :boot (i.c.boot/construct-command deps-mdws arguments)
                  :clojure-cli (i.c.clj/construct-command deps-mdws arguments iced-root)
                  :shadow-cljs (throw (ex-info "Currently iced command does not support shadow-cljs."
                                               {:description "Please see `:h vim-iced-manual-shadow-cljs` for manual setting up."}))
                  (throw (ex-info "Failed to detect clojure project." {:cwd cwd})))]
    (if (:dryrun options)
      (println (str/join " " command))
      (->> command
           (map #(str/replace % #"'" ""))
           (process/start)))))

(defn -repl-help
  [summary _errors]
  ;;FIXME
  (println summary))

(defn -repl
  "Main process for `repl` subcommand"
  [{:keys [iced-root cwd arguments]}]
  (let [;; Options not for vim-iced are handled as options for `lein`, `boot`, `clj` commands.
        ;; So separate them as arguments first.
        {arguments nil iced-option-args true} (group-by iced-option? arguments)
        {:keys [options _ summary errors]} (cli/parse-opts iced-option-args cli-options)]
    (if (:help options)
      (-repl-help summary errors)
      (-repl-start iced-root cwd options arguments))))

(defn -help
  [iced-root]
  (let [ver (version/string iced-root)]
    (println (format base-help-text ver))))

(defn -main
  [cwd iced-root & args]
  (let [[subcommand & arguments] args]
    (try
      (case subcommand
        "repl" (-repl {:iced-root iced-root :cwd cwd :arguments arguments})
        "version" (println (version/string iced-root))
        (-help iced-root))

      (catch clojure.lang.ExceptionInfo ex
        (print-error-log (.getMessage ex))
        (when-let [desc (some-> ex ex-data :description)]
          (println desc))
        (System/exit 1)))))
