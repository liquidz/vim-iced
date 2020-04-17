(ns iced.leiningen-test
  (:require
   [clojure.java.io :as io]
   [clojure.test :as t]
   [iced.leiningen :as sut]))

(def ^:private project-file-with-cljs
  (io/file "test" "resources" "iced_command" "leiningen_cljs" "project.clj"))

(def ^:private project-file-without-cljs
  (io/file "test" "resources" "iced_command" "leiningen_no_cljs" "project.clj"))

(t/deftest using-cljs?-test
  (t/is (true? (sut/using-cljs?
                (slurp project-file-with-cljs))))
  (t/is (false? (sut/using-cljs?
                 (slurp project-file-without-cljs))))
  (t/is (false? (sut/using-cljs?
                 "(defproject foo \"0.1.0\"
                    :dependencies [[bar \"xxx\"
                                    :exclusions [pre/dummy
                                                 org.clojure/clojurescript
                                                 post/dummy]]])"))))

(t/deftest dependencies->args-test
  (let [deps {'foo {:mvn/version "1"}
              'bar {:mvn/version "2"}}]
    (t/is (= #{["update-in" ":dependencies" "conj" "'[foo \"1\"]'"]
               ["update-in" ":dependencies" "conj" "'[bar \"2\"]'"]}
             (set (sut/dependencies->args deps))))))

(t/deftest middlewares->args-test
  (let [mdws ["foo" "bar"]]
    (t/is (= #{["update-in" ":repl-options:nrepl-middleware" "conj" "'foo'"]
               ["update-in" ":repl-options:nrepl-middleware" "conj" "'bar'"]}
             (set (sut/middlewares->args mdws))))))
