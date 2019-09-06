(clojure.core/let [n (clojure.core/create-ns  'vim-iced.loaded.shadow-cljs)]
  (clojure.core/intern
    (clojure.core/ns-name n)
    'validate-config
    (clojure.core/fn [vim-iced-home-dir config-path]
      (clojure.core/require 'clojure.edn
                            'clojure.java.io
                            'clojure.set
                            'clojure.string)
      (clojure.core/let [read-edn #(clojure.core/-> % clojure.core/slurp clojure.edn/read-string)
                         shadow-cljs-config (read-edn config-path)
                         deps-edn (read-edn (clojure.java.io/file vim-iced-home-dir "deps.edn"))
                         target-deps #{'cider/cider-nrepl 'refactor-nrepl 'iced-nrepl}
                         deps-diff (clojure.set/difference
                                     (clojure.core/->> (:deps deps-edn)
                                                       (clojure.core/filter #(target-deps (clojure.core/first %)))
                                                       (clojure.core/map (clojure.core/juxt clojure.core/first
                                                                                            (clojure.core/comp
                                                                                              :mvn/version
                                                                                              clojure.core/second)))
                                                       clojure.core/set)
                                     (clojure.core/->> (:dependencies shadow-cljs-config)
                                                       (clojure.core/filter #(target-deps (clojure.core/first %)))
                                                       clojure.core/set))
                         mdws-diff (clojure.set/difference
                                     (clojure.core/set (clojure.core/map clojure.core/symbol (:__middlewares__ deps-edn)))
                                     (clojure.core/set (clojure.core/get-in shadow-cljs-config [:nrepl :middleware])))]
        (clojure.string/join
          "\n"
          (clojure.core/concat
            (clojure.core/map (clojure.core/fn [[sym ver]] (clojure.core/str "Missing dependency: " sym " => " ver)) deps-diff)
            (clojure.core/map (clojure.core/fn [mdw]       (clojure.core/str "Missing middleware: " mdw)) mdws-diff)))))))
