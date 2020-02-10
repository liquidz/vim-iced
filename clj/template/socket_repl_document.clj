(when-let [{:keys [name arglists doc]} (some-> '%s resolve meta)]
  (when (or arglists doc)
    (let [str-join (fn [sep ls] (apply str (drop-last (interleave ls (repeat sep)))))]
      (cond-> [(str "*" name "*")]
        arglists (conj (str-join " " arglists))
        doc (conj doc)
        :always (->> (str-join "\n"))))))

