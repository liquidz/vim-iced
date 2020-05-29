(ns iced.common.color)

(defn- colorize
  [code s]
  (str "\033[" code "m" s "\033[m"))

(def bold (partial colorize 1))
(def red (partial colorize 31))
(def green (partial colorize 32))
