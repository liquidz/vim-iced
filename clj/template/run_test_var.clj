(do (require 'clojure.test)
    (let [summary (atom {:test 0 :pass 0 :fail 0 :error 0})
          errors (atom [])
          testing-var (atom nil)
          report (fn [m]
                   (case (:type m)
                     :pass (swap! summary update (:type m)  inc)
                     :fail  (do (swap! summary update (:type m) inc)
                                (swap! errors conj (assoc m
                                                          :ns (namespace @testing-var)
                                                          :var (name @testing-var))))
                     :error (do (swap! summary update (:type m) inc)
                                (swap! errors conj (assoc m
                                                          :ns (namespace @testing-var)
                                                          :var (name @testing-var))))
                     :begin-test-var (do (swap! summary update :test inc)
                                         (reset! testing-var (symbol (:var m))))
                     :end-test-var (reset! testing-var nil)
                     nil))]
      (binding [clojure.test/report report]
        (clojure.test/test-var #'%s))
      {:summary @summary
       :errors @errors}))

