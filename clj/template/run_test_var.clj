(do (require 'clojure.test)
    (let [ignore-keys [%s]
          summary (atom {:test 0 :pass 0 :fail 0 :error 0 :var 0})
          results (atom {})
          testing-var (atom nil)
          testing-ns (atom nil)
          to-str (fn [x]
                   (if (instance? Throwable x)
                     (str (class x) ": " (.getMessage x) (ex-data x))
                     (pr-str x)))
          report (fn [m]
                   (case (:type m)
                     (:pass :fail :error) (let [ns' (some-> @testing-var namespace)
                                                var' (some-> @testing-var name)
                                                m (-> (assoc m :ns ns' :var var')
                                                      (update :expected to-str)
                                                      (update :actual to-str))
                                                m (apply dissoc m ignore-keys)]
                                            (swap! summary update (:type m) inc)
                                            (swap! results update-in [ns' var'] conj m))

                     :begin-test-var (let [var-meta (some-> m :var meta)
                                           ns-name' (some-> var-meta :ns ns-name str)
                                           var-name' (some-> var-meta :name str)]
                                       (swap! summary update :test inc)
                                       (swap! summary update :var inc)
                                       (when (and ns-name' var-name')
                                         (reset! testing-var (symbol ns-name' var-name')))
                                       (when ns-name'
                                         (reset! testing-ns ns-name')))

                     :end-test-var (reset! testing-var nil)
                     nil))]
      (binding [clojure.test/report report]
        (clojure.test/test-vars %s))
      (cond-> {:summary @summary
               :results @results}
        @testing-ns (assoc :testing-ns @testing-ns))))