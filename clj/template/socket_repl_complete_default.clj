(let [base #"^%s"
      sep ";:;:"
      str-join (fn [sep ls] (apply str (drop-last (interleave ls (repeat sep)))))
      var->candidate (fn [v]
                       (let [vmeta (meta v)
                             var-name (str (:name vmeta))]
                         (if-let [args (:arglists vmeta)]
                           (->> args (map str) (str-join " ")
                                (list var-name)
                                (str-join sep))
                           var-name)))
      ns-names (->> (ns-map *ns*) vals (map var->candidate))
      alias-names (->> (ns-aliases *ns*)
                       (mapcat (fn [[alias-name ns*]]
                                 (map (fn [v] (str alias-name "/" (var->candidate v)))
                                      (vals (ns-publics ns*))))))
      all-names (concat ns-names alias-names)]
  (->> all-names
       (filter (fn [s] (re-seq base s)))
       (str-join "\n")))
