(ns iced.core-test
  (:require
   [clojure.test :as t]
   [iced.core :as sut]))

(t/deftest lein-using-cljs?-test
  (t/is (true? (sut/lein-using-cljs?
                "(defproject foo \"0.1.0\"
                   :dependencies [[foo \"xxx\"]
                                  [org.clojure/clojurescript \"xxx\"]])")))
  (t/is (false? (sut/lein-using-cljs?
                 "(defproject foo \"0.1.0\"
                    :dependencies [[foo \"xxx\"]
                                   [bar \"xxx\"
                                    :exclusions [org.clojure/clojurescript]]])")))
  (t/is (false? (sut/lein-using-cljs?
                 "(defproject foo \"0.1.0\"
                    :dependencies [[bar \"xxx\"
                                    :exclusions [pre/dummy
                                                 org.clojure/clojurescript
                                                 post/dummy]]])"))))
