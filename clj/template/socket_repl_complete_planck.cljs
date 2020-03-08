(let [str-join (fn [sep ls] (apply str (drop-last (interleave ls (repeat sep)))))]
  (->> (planck.repl/get-completions "%s")
       js->clj
       (str-join "\n")))
