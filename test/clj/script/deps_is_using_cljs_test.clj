(ns deps-is-using-cljs-test
  (:require
   [clojure.test :as t]
   [deps-is-using-cljs :as sut]))

(t/deftest using-cljs?-test
  (t/is (true? (sut/using-cljs?
                "{:paths [\"src\"]
                  :deps {foo {:mvn/version \"xxx\"}
                         org.clojure/clojurescript {:mvn/version \"xxx\"}}}")))

  (t/is (false? (sut/using-cljs?
                 "{:paths [\"src\"]
                   :deps {foo {:mvn/version \"xxx\"}
                          bar {:mvn/version \"xxx\"
                               :exclusions [org.clojure/clojurescript]}}}")))

  (t/is (false? (sut/using-cljs?
                 "{:paths [\"src\"]
                   :deps {bar {:mvn/version \"xxx\"
                               :exclusions [pre/dummy
                                            org.clojure/clojurescript
                                            post/dummy]}}}"))))
