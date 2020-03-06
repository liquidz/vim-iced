(let [base #"^%s"
      str-join (fn [sep ls] (apply str (drop-last (interleave ls (repeat sep)))))
      ns-names (->> (ns-map *ns*) keys (map str))
      alias-names (->> (ns-aliases *ns*)
                       (mapcat (fn [[k v]]
                                 (map (fn [s] (str k "/" s)) (keys (ns-publics v))))))
      all-names (concat ns-names alias-names)]
  (->> all-names
       (filter (fn [s] (re-seq base s)))
       (str-join "\n")))
