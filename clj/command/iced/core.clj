(ns iced.core
  (:require
   [clojure.edn :as edn]
   [clojure.java.io :as io]
   [clojure.set :as set]
   [clojure.string :as str]
   [clojure.tools.cli :as cli]
   [clojure.walk :as walk]
   [iced.boot :as i.boot]
   [iced.leiningen :as i.lein]))

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

(def option-names
  (->> cli-options
       (mapcat (juxt first second))
       (remove nil?)
       (map #(if-let [i (str/index-of % "=")]
               (subs % 0 i)
               %))))

(defn- iced-option?
  [s]
  (some #(str/starts-with? s %) option-names))

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
  "with-cljs, with-kaocha などのフラグ向けの設定を取得する"
  [config options]
  (for [[op _] options
        :when (contains? (:aliases config) op)]
    (get-in config [:aliases op])))

(defn fetch-dependencies-and-middlewares
  "オプションに沿った依存ライブラリとミドルウェアを取得する"
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
  "repl サブコマンド向けのオプションからFIXME"
  [cwd options]
  (let [detected-project (if (:instant options)
                           {:clojure-cli (io/file cwd)}
                           (detect-project-types cwd))
        detected-project (cond-> detected-project
                           (:force-boot options) (dissoc :leiningen :clojure-cli)
                           (:force-clojure-cli options) (dissoc :leiningen :boot))

        [project-type project-dir] (some #(when-let [project-dir (get detected-project %)]
                                            [% project-dir]) project-priority)
        project-file (io/file project-dir (get project->file-map project-type))

        ;; clojurescript 利用の自動検知
        options (if (and (= :leiningen project-type)
                         (not (:without-cljs options))
                         (not (:cljs options))
                         (i.lein/using-cljs? (slurp project-file)))
                  (assoc options :cljs true)
                  options)]
    {:project-type project-type
     :project-file project-file
     :options options}))

(defn print-command-result
  "フロントにある shellscript で実行できるコマンドを標準出力に流す"
  [command-coll]
  (println (str "ICED-COMMAND\t" (str/join " " command-coll))))

(defn -repl
  [{:keys [iced-root cwd options arguments]}]
  (let [config (deps-edn iced-root)
        {:keys [project-type options]} (parse-options cwd options)
        deps-mdws (fetch-dependencies-and-middlewares config options)]
    (case project-type
      :leiningen (print-command-result (i.lein/construct-command deps-mdws arguments))
      :boot (print-command-result (i.boot/construct-command deps-mdws arguments))
      ; :clojure-cli (str "CLI" project-dir-file)
      (throw (ex-info "Failed to detect clojure project" {:cwd cwd}))
      )
    ))

(defn -main [cwd iced-root & args]
  (let [;; iced 向けでないオプションは lein, boot, clj コマンドのオプションとして扱うので先に arguments として分離しておく
        {arguments nil iced-option-args true} (group-by iced-option? args)
        {:keys [options _ summary errors]} (cli/parse-opts iced-option-args cli-options)
        [subcommand & arguments] arguments]
    (case subcommand
      "repl" (-repl {:iced-root iced-root :cwd cwd :options options :arguments arguments})
      "help" (println "FIXME help")
      "version" (println "FIXME version"))))

(comment
  (def +merr-dir+ "/Users/uochan/src/github.com/liquidz/merr")
  (def +iced-root+ "/Users/uochan/src/github.com/liquidz/vim-iced")
    (-main +merr-dir+ +iced-root+ "repl" "--with-kaocha" "-with-profile" "XXX"
           "--dependency=foo:0.4.3"
           "--dependency=bar:0.4.3"
           "--middleware=iced.nrepl/wrap-iced"
           "--middleware=iced.nrepl/wrap-iced2"))
