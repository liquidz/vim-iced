(ns lein-is-using-cljs-test
  (:require
   [clojure.test :as t]
   [lein-is-using-cljs :as sut]))

(t/deftest using-cljs?-test
  (t/is (true?  (sut/using-cljs?
                 "(defproject foo \"0.1.0\"
                        :dependencies [[foo \"xxx\"]
                                       [org.clojure/clojurescript \"xxx\"]])")))

  (t/is (false? (sut/using-cljs?
                 "(defproject foo \"0.1.0\"
                    :dependencies [[foo \"xxx\"]
                                   [bar \"xxx\"
                                    :exclusions [org.clojure/clojurescript]]])")))
  (t/is (false? (sut/using-cljs?
                 "(defproject foo \"0.1.0\"
                    :dependencies [[bar \"xxx\"
                                    :exclusions [pre/dummy
                                                 org.clojure/clojurescript
                                                 post/dummy]]])"))))
