(do (require 'clojure.test)
    (let [summary (atom {:test 0 :pass 0 :fail 0 :error 0})
          report (fn [m]
                   (case (:type m)
                     :pass (swap! summary update (:type m)  inc)
                     :fail  (swap! summary update (:type m) inc)
                     :error (swap! summary update (:type m) inc)
                     :begin-test-var (swap! summary update :test inc)
                     nil))]
      (binding [clojure.test/report report]
        (clojure.test/test-var #'%s))
      {:results []
       :summary @summary
       :testing-ns []}))
