(ns lein-is-using-cljs-test
  (:require
   [clojure.test :as t]
   [lein-is-using-cljs :as sut]))

(t/deftest read-string*-test
  (t/testing "multiple expressions"
    (t/is (= '[(hello) (world)]
             (sut/read-string* "(hello) (world)"))))
  (t/testing "tilde"
    (t/is (= '[(hello world)]
             (sut/read-string* "(hello ~world)"))))
  (t/testing "regexp"
    (t/is (= '[(hello "world")]
             (sut/read-string* "(hello #\"world\")"))))
  (t/testing "#="
    (t/is (= '[(hello (slurp "world.txt"))]
             (sut/read-string* "(hello #=(slurp \"world.txt\"))"))))
  (t/testing "#()"
    (t/is (= '[(hello (world))]
             (sut/read-string* "(hello #(world))"))))
  (t/testing "#{}"
    (t/is (= '[(hello #{world})]
             (sut/read-string* "(hello #{world})")))))

(t/deftest using-cljs?-test
  (t/is (true? (sut/using-cljs?
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
