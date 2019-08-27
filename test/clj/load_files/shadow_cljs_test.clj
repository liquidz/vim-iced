(ns load-files.shadow-cljs-test
  (:require [clojure.string :as str]
            [clojure.test :as t]))

(load-file "clj/load_files/shadow_cljs.clj")

(t/deftest validate-config-test
  (t/testing "failure"
    (let [res (vim-iced.loaded.shadow-cljs/validate-config
                "./test/resources/shadow_cljs/fail"
                "./test/resources/shadow_cljs/fail/shadow-cljs.edn") ]
      (t/is (= ["Missing dependency: cider/cider-nrepl => 0.22.0-beta12"
                "Missing dependency: iced-nrepl => 0.6.0"
                "Missing middleware: cider.nrepl/wrap-clojuredocs"
                "Missing middleware: cider.nrepl/wrap-xref"]
               (-> res str/split-lines sort)))))

  (t/testing "success"
    (let [res (vim-iced.loaded.shadow-cljs/validate-config
                "./test/resources/shadow_cljs/success"
                "./test/resources/shadow_cljs/success/shadow-cljs.edn") ]
      (t/is (str/blank? res)))))
