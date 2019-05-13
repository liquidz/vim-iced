(ns iced-jackin
  (:require [clojure.java.io :as io]
            [clojure.math.combinatorics :as combo]
            [clojure.string :as str]
            [org.panchromatic.mokuhan :as mokuhan]))

;; must be same as :aliases keys in deps.edn
;; - cljs = 1
;; - next = 2
;; - nnext = 4
(def ^:private aliases
  {"cljs" 1})

(defn- deps->map [deps]
  (reduce (fn [res [name {:mvn/keys [version]}]]
            (assoc res name version))
          {} deps))

(def ^:private config
  (-> "deps.edn" slurp read-string))

(def ^:private default-dependencies
  (deps->map (:deps config)))

(def ^:private default-middlewares
  (:__middlewares__ config))

(defn- get-config [alias-name]
  (let [alias-map (get-in config [:aliases (keyword alias-name)])]
    {:dependencies (some->> alias-map :extra-deps deps->map)
     :middlewares (some->> alias-map :__middlewares__)}))


(defn- config-merge [c1 c2]
  {:dependencies (merge (:dependencies c1) (:dependencies c2))
   :middlewares (vec (concat (:middlewares c1) (:middlewares c2)))})

(def ^:private all-config-list
  (let [subsets (combo/subsets (keys aliases))
        base {:dependencies default-dependencies :middlewares default-middlewares}]
    (reduce (fn [acc alias-set]
              (let [index (apply + (map #(get aliases % 0) alias-set))
                    configs (map #(get-config %) alias-set)]
                (assoc acc index
                       (reduce config-merge base configs))))
            (vec (repeat (count subsets) nil))
            subsets)))

(defn bash-list [ls]
  (str "'" (str/join " " ls) "'"))

(defn- bash-map [m]
  (str "'" (->> m (map  #(apply format "%s:%s" %)) (str/join " ")) "'"))

(defn -main []
  (let [file (io/file "bin/iced")]
    (->> {:dependencies (map (comp bash-map :dependencies) all-config-list)
          :middlewares (map (comp bash-list :middlewares) all-config-list)}
         (mokuhan/render (slurp "clj/template/iced.bash"))
         (spit file))
    (.setExecutable file true)
    (System/exit 0)))
