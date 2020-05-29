(ns iced.common.version
  (:require
   [clojure.java.io :as io]
   [clojure.string :as str]))

(defn string*
  [iced-root]
  (let [lines (-> (io/file iced-root "doc" "vim-iced.txt")
                  slurp
                  (str/split #"[\r\n]+"))
        line (some #(and (str/starts-with? % "Version: ") %) lines)]
    (-> (str/trim line)
        (str/split #" ")
        second)))

(def string (memoize string*))
