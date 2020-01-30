(ns iced
  (:require [clojure.edn :as edn]
            [clojure.tools.cli :as cli]
            [clojure.java.io :as io]
            [clojure.string :as str]
            [clojure.walk :as walk]))

(def cli-options
  [[nil "--instant"]
   ["-h" "--help"]])

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

(defn lein-using-cljs? [project-dir]
  (let [file (io/file project-dir "project.clj")
        skip-exclusions? (atom false)
        result (atom false)]
    (->> (slurp file)
         read-string
         (filter #(= 'defproject (first %)))
         first
         (walk/postwalk
           (fn [x]
             (cond
               (and @skip-exclusions? (sequential? x) (apply = ::skip x)) (reset! skip-exclusions? false)
               @skip-exclusions? ::skip
               (= :exclusions x) (reset! skip-exclusions? true)
               (= 'org.clojure/clojurescript x) (reset! result true)
               :else x))))
    @result))




(defn -repl [{:keys [cwd options arguments]}]
  (let [[project-type project-dir-file] (if (:instant options)
                                          :clojure-cli
                                          (detect-project-type cwd))]
    (when-not project-type
      (throw (ex-info "Failed to detect clojure project" {:cwd cwd})))
    )
  )

(defn -main [cwd iced-root & args]
  (let [{:keys [options arguments summary errors]} (cli/parse-opts args cli-options)
        [subcommand & arguments] arguments]
    (println options)
    (println "----")
    (println arguments)
    (case subcommand
      "repl" (-repl {:cwd cwd :options options :arguments arguments})
      "help" (println "FIXME help")
      "version" (println "FIXME version"))))
