(ns shadow-cljs-validation-test
  (:require
   [shadow-cljs-validation :as sut]
   [clojure.java.io :as io]
   [clojure.test :as t]))

(def ^:private resource-dir
  (io/file "test" "resources" "shadow_cljs"))

(t/deftest normalize-deps-test
  (t/is (= '[foo/bar "baz"]
           (sut/normalize-deps '[foo/bar "baz"])))
  (t/is (= '[foo/foo "bar"]
           (sut/normalize-deps '[foo "bar"])))
  (t/is (= '[foo/bar "baz"]
           (sut/normalize-deps '[foo/bar {:mvn/version "baz"}])))
  (t/is (= '[foo/foo "bar"]
           (sut/normalize-deps '[foo {:mvn/version "bar"}]))))

(t/deftest filter-and-normalize-deps-test
  (let [required-deps  #{'foo/foo 'bar/bar}
        test-deps [['foo/foo "1.0"]
                   ['bar {:mvn/version "2.0"}]
                   ['baz "3.0"]]]
    (t/is (= #{['foo/foo "1.0"]
               ['bar/bar "2.0"]}
             (sut/filter-and-normalize-deps required-deps test-deps)))))

(defn- extract-shadow-cljs-dependency-set
  [file]
  (let [required-deps #{'cider/cider-nrepl
                        'iced-nrepl/iced-nrepl
                        'refactor-nrepl/refactor-nrepl}]
    (sut/extract-shadow-cljs-dependency-set
     required-deps
     file
     (sut/read-edn file))))

(t/deftest extract-shadow-cljs-dependency-set-test
  (t/testing "only shadow-cljs.edn"
    (t/is (= #{['cider/cider-nrepl "123"]
               ['refactor-nrepl/refactor-nrepl "234"]
               ['iced-nrepl/iced-nrepl "345"]}
             (-> (io/file resource-dir "deps" "shadow-cljs-default.edn")
                 extract-shadow-cljs-dependency-set))))

  (t/testing "shadow-cljs.edn and deps.edn"
    (t/is (= #{['cider/cider-nrepl "234"]
               ['refactor-nrepl/refactor-nrepl "345"]
               ['iced-nrepl/iced-nrepl "456"]}
             (-> (io/file resource-dir "deps" "shadow-cljs-deps.edn")
                 extract-shadow-cljs-dependency-set))))

  (t/testing "shadow-cljs.edn and deps.edn with aliases"
    (t/is (= #{['cider/cider-nrepl "987"]
               ['refactor-nrepl/refactor-nrepl "876"]
               ['iced-nrepl/iced-nrepl "765"]}
             (-> (io/file resource-dir "deps" "shadow-cljs-deps-alias.edn")
                 extract-shadow-cljs-dependency-set)))))

(t/deftest differences-test
  (t/testing "positive"
    (t/is (= {:dependencies #{}
              :middlewares #{}}
             (sut/differences
              (io/file resource-dir "success" "shadow-cljs.edn")
              resource-dir))))

  (t/testing "negative"
    (t/is (= {:dependencies #{['refactor-nrepl/refactor-nrepl "345"]
                              ['iced-nrepl/iced-nrepl "456"]}
              :middlewares #{'cider.nrepl/wrap-clojuredocs
                             'cider.nrepl/wrap-xref}}
             (sut/differences
              (io/file resource-dir "fail" "shadow-cljs.edn")
              resource-dir)))))
