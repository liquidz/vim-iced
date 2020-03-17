(ns iced.core-test
  (:require
   [clojure.java.io :as io]
   [clojure.test :as t]
   [iced.core :as sut]))

(t/deftest detect-project-type-test
  (doseq [[expected-kw dir-name] {:leiningen "leiningen"
                                  :boot "boot"
                                  :clojure-cli "clojure"}]
    (t/testing (name expected-kw)
      (let [cwd (.getAbsolutePath (io/file "test" "resources" "iced_command" dir-name "src"))
            [type-kw dir-file] (sut/detect-project-type cwd)]
        (t/is (= expected-kw type-kw))
        (t/is (= (.getAbsolutePath (io/file "test" "resources" "iced_command" dir-name))
                 (.getAbsolutePath dir-file)))))))
