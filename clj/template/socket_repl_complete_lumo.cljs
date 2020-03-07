(let [str-join (fn [sep ls] (apply str (drop-last (interleave ls (repeat sep)))))
      result (atom nil)
      callback (fn [resp]
                 (->> resp
                      (map str)
                      (str-join "\n")
                      (reset! result)))]
  (lumo.repl/get-completions "%s" callback)
  @result)
