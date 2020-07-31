(ns deps-is-using-cljs
  (:require
   [clojure.edn :as edn]
   [clojure.walk :as walk]))

(defn using-cljs?
  [deps-edn-content]
  (let [skip-exclusions? (atom false)
        result (atom false)]
    (->> deps-edn-content
         edn/read-string
         (walk/postwalk
          (fn [x]
            (cond
              (and @skip-exclusions? (sequential? x) (apply = ::skip x))
              (reset! skip-exclusions? false)

              @skip-exclusions?
              ::skip

              (= :exclusions x)
              (reset! skip-exclusions? true)

              (= 'org.clojure/clojurescript x)
              (reset! result true)

              :else x))))
    @result))

(defn -main
  [args]
  (when (not= 1 (count args))
    (System/exit 1))
  (try
    (System/exit (if (-> args first slurp using-cljs?) 0 1))
    (catch Exception _
      (println "Failed to check the use of ClojureScript")
      (System/exit 2))))

(when *command-line-args*
  (-main *command-line-args*))
