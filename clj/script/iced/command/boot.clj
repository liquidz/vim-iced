(ns iced.command.boot)

(defn dependencies->args
  [deps]
  (concat
   [["-i" "\"(require 'cider.tasks)\""]]
   (map (fn [[k {:mvn/keys [version]}]]
          ["-d" (format "%s:%s" k version)])
        deps)))

(defn middlewares->args
  [mdws]
  (concat
   [["--" "cider.tasks/add-middleware"]]
   (map vector (repeat "-m") mdws)))

(defn construct-command
  "Return command list like [\"foo\" \"-option\" \"value\"]."
  [{:keys [dependencies middlewares]} args]
  (flatten
   (concat
    ["boot"]
    (dependencies->args dependencies)
    (middlewares->args middlewares)
    ["--"]
    args
    ["repl"])))
