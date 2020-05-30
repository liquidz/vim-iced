(ns iced.command.core-test
  (:require
   [clojure.java.io :as io]
   [clojure.test :as t]
   [iced.command.core :as sut]
   [iced.command.leiningen :as i.lein]))

(defmacro with-alter-var-root [[v f] & body]
  `(let [org-value# @~v]
     (try
       (alter-var-root ~v (fn [_] ~f))
       ~@body
       (finally
         (alter-var-root ~v (fn [_] org-value#))))))

(def ^:private test-config
  {:deps {'base-dep {:mvn/version "1"}}
   :__middlewares__ ["base-mdw"]
   :aliases
   {:cljs {:extra-deps {'cljs-dep {:mvn/version "2"}}
           :__middlewares__ ["cljs-mdw"]}
    :kaocha {:extra-deps {'kaocha-dep {:mvn/version "3"}}
             :__middlewares__ ["kaocha-mdw"]}}})

(defn- same-path?
  [& files]
  (->> files
       (map #(.getAbsolutePath %))
       (apply =)))

(t/deftest detect-project-types-test
  (t/testing "leiningen"
    (let [cwd (.getAbsolutePath (io/file "test" "resources" "iced_command" "leiningen" "src"))
          result (sut/detect-project-types cwd)]
      ;; NOTE: detected vim-iced's deps.edn too
      (t/is (= #{:leiningen :clojure-cli}
               (set (keys result))))
      (t/is (same-path? (io/file "test" "resources" "iced_command" "leiningen")
                        (:leiningen result)))
      (t/is (same-path? (io/file "")
                        (:clojure-cli result)))))

  (t/testing "boot"
    (let [cwd (.getAbsolutePath (io/file "test" "resources" "iced_command" "boot" "src"))
          result (sut/detect-project-types cwd)]
      ;; NOTE: detected vim-iced's deps.edn too
      (t/is (= #{:boot :clojure-cli}
               (set (keys result))))
      (t/is (same-path? (io/file "test" "resources" "iced_command" "boot")
                        (:boot result)))
      (t/is (same-path? (io/file "")
                        (:clojure-cli result)))))

  (t/testing "clojure cli"
    (let [cwd (.getAbsolutePath (io/file "test" "resources" "iced_command" "clojure" "src"))
          result (sut/detect-project-types cwd)]
      (t/is (= #{:clojure-cli}
               (set (keys result))))
      ;; Should precede the first one to be found
      (t/is (same-path? (io/file "test" "resources" "iced_command" "clojure")
                        (:clojure-cli result)))))

  (t/testing "mixed"
    (let [cwd (.getAbsolutePath (io/file "test" "resources" "iced_command" "mixed" "src"))
          result (sut/detect-project-types cwd)]
      (t/is (= #{:leiningen :boot :clojure-cli}
               (set (keys result))))
      (t/is (same-path? (io/file "test" "resources" "iced_command" "mixed")
                        (:leiningen result)
                        (:boot result)
                        (:clojure-cli result))))))

(def ^:private fetch-dependencies-and-middlewares
  #(sut/fetch-dependencies-and-middlewares test-config %))

(t/deftest fetch-dependencies-and-middlewares-test
  (t/testing "no options"
    (let [res (fetch-dependencies-and-middlewares {})]
      (t/is (= {'base-dep {:mvn/version "1"}} (:dependencies res)))
      (t/is (= ["base-mdw"] (:middlewares res)))))

  (t/testing "flag options"
    (t/testing "--cljs"
      (let [res (fetch-dependencies-and-middlewares {:cljs true})]
        (t/is (= {'base-dep {:mvn/version "1"}
                  'cljs-dep {:mvn/version "2"}}
                 (:dependencies res)))
        (t/is (= ["base-mdw" "cljs-mdw"] (:middlewares res)))))

    (t/testing "--kaocha"
      (let [res (fetch-dependencies-and-middlewares {:kaocha true})]
        (t/is (= {'base-dep {:mvn/version "1"}
                  'kaocha-dep {:mvn/version "3"}}
                 (:dependencies res)))
        (t/is (= ["base-mdw" "kaocha-mdw"] (:middlewares res)))))

    (t/testing "all flag options"
      (let [res (fetch-dependencies-and-middlewares {:cljs true :kaocha true})]
        (t/is (= {'base-dep {:mvn/version "1"}
                  'cljs-dep {:mvn/version "2"}
                  'kaocha-dep {:mvn/version "3"}}
                 (:dependencies res)))
        (t/is (= #{"base-mdw" "cljs-mdw" "kaocha-mdw"}
                 (set (:middlewares res)))))))

  (t/testing "additional options"
    (t/testing "--dependency"
      (let [option {:dependency ["foo:4" "bar:5"]}
            res (fetch-dependencies-and-middlewares option)]
        (t/is (= {'base-dep {:mvn/version "1"}
                  'foo {:mvn/version "4"}
                  'bar {:mvn/version "5"}}
                 (:dependencies res)))
        (t/is (= ["base-mdw"] (:middlewares res)))))

    (t/testing "--middleware"
      (let [option {:middleware ["foo" "bar"]}
            res (fetch-dependencies-and-middlewares option)]
        (t/is (= {'base-dep {:mvn/version "1"}}
                 (:dependencies res)))
        (t/is (= ["base-mdw" "foo" "bar"] (:middlewares res))))))

  (t/testing "flag and additional options"
    (let [option {:cljs true
                  :dependency ["foo:4"] :middleware ["bar"]}
          res (fetch-dependencies-and-middlewares option)]
      (t/is (= {'base-dep {:mvn/version "1"}
                'cljs-dep {:mvn/version "2"}
                'foo {:mvn/version "4"}}
               (:dependencies res)))
      (t/is (= ["base-mdw" "cljs-mdw" "bar"] (:middlewares res))))))

(t/deftest detect-project-test
  (let [cwd (.getAbsolutePath (io/file "test" "resources" "iced_command" "mixed" "src"))]
    (t/testing "leiningen has priority"
      (let [res (sut/detect-project cwd {})]
        (t/is (= :leiningen (:project-type res)))
        (t/is (= (.getAbsolutePath (io/file "test" "resources" "iced_command" "mixed" "project.clj"))
                 (.getAbsolutePath (:project-file res))))))

    (t/testing "force-boot"
      (let [res (sut/detect-project cwd {:force-boot true})]
        (t/is (= :boot (:project-type res)))
        (t/is (= (.getAbsolutePath (io/file "test" "resources" "iced_command" "mixed" "build.boot"))
                 (.getAbsolutePath (:project-file res))))))

    (t/testing "force-clojure-cli"
      (let [res (sut/detect-project cwd {:force-clojure-cli true})]
        (t/is (= :clojure-cli (:project-type res)))
        (t/is (= (.getAbsolutePath (io/file "test" "resources" "iced_command" "mixed" "deps.edn"))
                 (.getAbsolutePath (:project-file res))))))))

(t/deftest cljs-auto-detected?-test
  (let [project-file (.getAbsolutePath (io/file "test" "resources" "iced_command" "mixed" "project.clj"))]
    (t/testing "Should detected automatically"
      (let [auto-detected? (atom false)]
        (with-alter-var-root [#'i.lein/using-cljs? (fn [_] (reset! auto-detected? true) true)]
          (t/is (true? (sut/cljs-auto-detected? {} :leiningen project-file)))
          (t/is (true? @auto-detected?)))))

    (t/testing "Should **NOT** detected automatically"
      (let [auto-detected? (atom false)]
        (with-alter-var-root [#'i.lein/using-cljs? (fn [_] (reset! auto-detected? true) true)]
          (t/testing "with-cljs が指定されていれば自動検知されないこと"
            (t/is (false? (sut/cljs-auto-detected? {:cljs true} :leiningen project-file)))
            (t/is (false? @auto-detected?)))

          (t/testing "without-cljs が指定されている"
            (t/is (false? (sut/cljs-auto-detected? {:without-cljs true} :leiningen project-file)))
            (t/is (false? @auto-detected?)))

          (t/testing "leiningen じゃない"
            (t/is (false? (sut/cljs-auto-detected? {} :clojure-cli project-file)))
            (t/is (false? @auto-detected?))))))))
