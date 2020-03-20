(import java.net.ServerSocket)

(with-open [sock (ServerSocket. 0)]
  (.getLocalPort sock))
