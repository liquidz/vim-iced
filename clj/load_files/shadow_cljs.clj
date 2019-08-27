(def ___vim-iced-shadow-cljs-ns___ 'vim-iced.loaded.shadow-cljs)
(create-ns ___vim-iced-shadow-cljs-ns___)

(intern
 ___vim-iced-shadow-cljs-ns___
 'validate-config
 (fn [vim-iced-home-dir config-path]
   (require 'clojure.edn
            'clojure.java.io
            'clojure.set
            'clojure.string)
   (let [read-edn #(-> % slurp clojure.edn/read-string)
         shadow-cljs-config (read-edn config-path)
         deps-edn (read-edn (clojure.java.io/file vim-iced-home-dir "deps.edn"))
         target-deps #{'cider/cider-nrepl 'refactor-nrepl 'iced-nrepl}
         deps-diff (clojure.set/difference
                    (->> (:deps deps-edn)
                         (filter #(target-deps (first %)))
                         (map (juxt first (comp :mvn/version second)))
                         set)
                    (->> (:dependencies shadow-cljs-config)
                         (filter #(target-deps (first %)))
                         set))
         mdws-diff (clojure.set/difference
                    (set (map symbol (:__middlewares__ deps-edn)))
                    (set (get-in shadow-cljs-config [:nrepl :middleware])))]
     (clojure.string/join
      "\n"
      (concat
       (map (fn [[sym ver]] (str "Missing dependency: " sym " => " ver)) deps-diff)
       (map (fn [mdw]       (str "Missing middleware: " mdw)) mdws-diff))))))
