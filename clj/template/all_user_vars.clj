(do (require 'clojure.java.io)
    (let [user-dir (System/getProperty "user.dir")
          dir-name (.getName (clojure.java.io/file user-dir))]
      (->> (all-ns)
           (map ns-name)
           (filter #(not= -1 (.indexOf (str %) dir-name)))
           (mapcat (comp vals ns-interns)))))
