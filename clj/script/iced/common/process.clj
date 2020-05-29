(ns iced.common.process)

(defn start
  [command-list]
  (let [pb (doto (ProcessBuilder. command-list)
             (.redirectOutput java.lang.ProcessBuilder$Redirect/INHERIT)
             (.redirectInput java.lang.ProcessBuilder$Redirect/INHERIT))
        p (.start pb)]
    (.waitFor p)))


