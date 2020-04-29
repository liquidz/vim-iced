(ns iced.boot)

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
  [dm args]
  (flatten
   (concat
    ["boot"]
    (dependencies->args (:dependencies dm))
    (middlewares->args (:middlewares dm))
    ["--"]
    args
    ["repl"])))
