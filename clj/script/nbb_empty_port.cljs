(ns nbb-empty-port
  (:require
    ["net" :as net]))

(let [server (net/createServer)]
  (.on server "listening" (fn []
                            (print (.-port (.address server)))
                            (.close server)))
  (js/Promise.
   (fn [resolve reject]
     (.on server "close" (fn [] (resolve true)))
     (.on server "error" (fn [err] (reject err)))
     (.listen server 0 "localhost"))))
