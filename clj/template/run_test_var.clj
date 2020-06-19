(do (require 'clojure.test)
    (let [summary (atom {:test 0 :pass 0 :fail 0 :error 0 :var 0})
          results (atom {})
          testing-var (atom nil)
          report (fn [m]
                   (case (:type m)
                     :pass (swap! summary update (:type m)  inc)

                     (:fail :error) (let [ns' (namespace @testing-var)
                                          var' (name @testing-var)]
                                      (swap! summary update (:type m) inc)
                                      (swap! results update-in [ns' var'] conj (assoc m :ns ns' :var var')))

                     :begin-test-var (do (swap! summary update :test inc)
                                         (swap! summary update :var inc)
                                         (reset! testing-var (symbol (:var m))))

                     :end-test-var (reset! testing-var nil)
                     nil))]
      (binding [clojure.test/report report]
        (clojure.test/test-var #'%s))
      {:summary @summary
       :results @results}))
