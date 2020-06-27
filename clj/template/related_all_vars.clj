(->> (all-ns)
     (map ns-name)
     (filter (fn [name] (not= -1 (.indexOf (str name) "%s"))))
     (mapcat (comp vals ns-interns)))
