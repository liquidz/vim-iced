(require 'clojure.test)
(let [current-report (atom {})
      report (fn [m]
               (case (:type m)
                 :pass (swap! current-report update (:type m) (fnil inc 0))
                 :fail  (swap! current-report update (:type m) (fnil inc 0))
                 :error (swap! current-report update (:type m) (fnil inc 0))
                 :begin-test-var (swap! current-report update :test (fnil inc 0))
                 nil))]
  (binding [clojure.test/report report]
    (clojure.test/test-var #'%s))
  (merge {:test 0 :pass 0 :fail 0 :error 0}
         @current-report))
