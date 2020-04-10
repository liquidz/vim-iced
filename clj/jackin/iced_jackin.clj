(ns iced-jackin
  (:require [clojure.java.io :as io]
            [clojure.string :as str]
            [clojure.test :as t]
            [org.panchromatic.mokuhan :as mokuhan]))

(defn- deps->map [deps]
  (reduce (fn [res [name {:mvn/keys [version]}]]
            (assoc res name version))
          {} deps))
(t/deftest deps->map-test ; {{{
  (t/is (= {'foo/bar "0.0.1"}
           (deps->map {'foo/bar {:mvn/version "0.0.1"}})))) ; }}}

(def ^:private config
  (-> "deps.edn" slurp read-string))

(def ^:private command-option-aliases
  (->> config
       :aliases
       (keep (fn [[k v]] (and (:__command_option__ v) (name k))))))

(def ^:private default-dependencies
  (deps->map (:deps config)))

(def ^:private default-middlewares
  (:__middlewares__ config))

(defn- get-alias-config [alias-name]
  (when-let [alias-map (get-in config [:aliases (keyword alias-name)])]
    {:dependencies (some->> alias-map :extra-deps deps->map)
     :middlewares (some->> alias-map :__middlewares__)}))
(t/deftest get-alias-config-test ; {{{
  (let [{:keys [dependencies middlewares]} (get-alias-config "cljs")]
    (t/is (map? dependencies))
    (t/is (vector? middlewares)))
  (t/is (nil? (get-alias-config "unknown-alias")))) ; }}}

(defn bash-list [ls]
  (str "'" (str/join " " ls) "'"))

(defn- bash-map [m]
  (str "'" (->> m (map  #(apply format "%s:%s" %)) (str/join " ")) "'"))

(defn all-command-option-configs [aliases]
  (keep (fn [alias-name]
          (when-let [{:keys [dependencies middlewares]} (get-alias-config alias-name)]
            {:name (str/upper-case alias-name)
             :dependencies (bash-map dependencies)
             :middlewares (bash-list middlewares)}))
        aliases))
(t/deftest all-command-option-configs-test ; {{{
  (let [[first-config :as res] (all-command-option-configs ["cljs" "unknown"])]
    (t/is (= 1 (count res)))
    (t/is (= "CLJS" (:name first-config)))
    (t/is (contains? first-config :dependencies))
    (t/is (contains? first-config :middlewares)))) ; }}}

(defn -main []
  (let [file (io/file "bin/iced")]
    (->> {:base-dependencies (bash-map default-dependencies)
          :base-middlewares (bash-list default-middlewares)
          :option-configs (all-command-option-configs command-option-aliases)}
         (mokuhan/render (slurp "clj/template/iced.bash"))
         (spit file))
    (.setExecutable file true)
    (System/exit 0)))

; vim:fdm=marker:fdl=0
