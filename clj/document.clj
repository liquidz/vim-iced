(ns document
  (:require [clojure.edn :as edn]
            [clojure.string :as str]
            [zprint.core :as zp]
            iced-repl))

(def templates
  {".template/README.md" "README.md"
   ".template/vim-iced.txt" "doc/vim-iced.txt"})

(defn read-deps []
  (-> (slurp "deps.edn")
      edn/read-string
      :deps))

(def ^:private zprint-option
  {:map {:comma? false}})

(defn deps->lein-profile [deps]
  (let [deps (map (fn [[lib {ver :mvn/version}]] [lib ver]) deps)
        lein-plugins #{'refactor-nrepl}
        plugins (filter (comp lein-plugins first) deps)
        dependencies (remove (comp lein-plugins first) deps)
        middlewares (->> iced-repl/middlewares
                         (remove #(= % "refactor-nrepl.middleware/wrap-refactor"))
                         (map symbol))]
    (with-out-str
      (zp/zprint
       {:user
        {:dependencies (vec dependencies)
         :plugins (vec plugins)
         :repl-options {:nrepl-middleware (vec middlewares)}}}
       zprint-option))))

(defn deps->boot-profile [deps]
  (let [deps (map (fn [[lib {ver :mvn/version}]] [lib ver]) deps)
        middlewares (map symbol iced-repl/middlewares)]
    (with-out-str
      (doseq [sexp ['(require 'boot.repl)
                    `(~'swap! boot.repl/*default-dependencies*
                              ~'concat '[~@deps])
                    `(~'swap! boot.repl/*default-middleware*
                              ~'concat '[~@middlewares])]]
        (zp/zprint sexp zprint-option)
        (print "\n")))))

(defn indent
  ([s] (indent s 2))
  ([s n]
   (let [spaces (str/join (repeat n " "))
         delm (str "\n" spaces)]
     (str spaces (-> (str/trim s) (str/replace #"[\r\n]" delm))))))

(defn -main []
  (let [deps (read-deps)
        lein-profile (indent (deps->lein-profile deps))
        boot-profile (indent (deps->boot-profile deps))]
    (doseq [[from-file to-file] templates]
      (let [body (-> (slurp from-file)
                     (str/replace "{{{lein-profile}}}" lein-profile)
                     (str/replace "{{{boot-profile}}}" boot-profile))]
        (spit to-file body)))
    (System/exit 0)))
