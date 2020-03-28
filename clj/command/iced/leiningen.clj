(ns iced.leiningen
  (:require
   [clojure.edn :as edn]
   [clojure.string :as str]
   [clojure.walk :as walk]))

(defn read-string* [s]
  (-> (str "[ " s " ]")
      (str/replace "~" "")
      (str/replace "#\"" "\"")
      (str/replace "#=(" "(")
      edn/read-string))

(defn using-cljs? [project-clj-content]
  (let [skip-exclusions? (atom false)
        result (atom false)]
    (->> project-clj-content
         read-string*
         (filter #(= 'defproject (first %)))
         first
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

(defn dependencies->args
  [deps]
  (map (fn [[k {:mvn/keys [version]}]]
         ["update-in" ":dependencies" "conj"
          (format "'[%s \"%s\"]'" k version)])
       deps))

(defn middlewares->args
  [mdws]
  (map (fn [mdw]
         ["update-in" ":repl-options:nrepl-middleware" "conj"
          (format "'%s'" mdw)])
       mdws))




(comment
  (def +merr-dir+ "/Users/iizuka/src/github.com/liquidz/merr")
  (def +iced-root+ "/Users/iizuka/src/github.com/liquidz/vim-iced")
  (def +deps+
    (-> (str +iced-root+ "/deps.edn")
        slurp
        edn/read-string))

  )
