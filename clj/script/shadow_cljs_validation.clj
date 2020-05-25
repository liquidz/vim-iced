(ns shadow-cljs-validation
  (:require
   [clojure.edn :as edn]
   [clojure.java.io :as io]
   [clojure.set :as set]
   [clojure.string :as str]))

(defn read-edn
  [path]
  (-> path slurp edn/read-string))

(defn normalize-deps
  [[name ver]]
  (if (map? ver)
    [name  (:mvn/version ver)]
    [name ver]))

(defn filter-and-normalize-deps
  [required-deps deps]
  (->> deps
       (filter (comp required-deps first))
       (map normalize-deps)
       set))

(defn extract-shadow-cljs-dependency-set
  [required-deps shadow-cljs-config-path shadow-edn]
  (cond
    ;; c.f. https://shadow-cljs.github.io/docs/UsersGuide.html#deps-edn
    (contains? shadow-edn :deps)
    (let [conf (:deps shadow-edn)
          edn (read-edn (io/file (.getParent (io/file shadow-cljs-config-path))
                                 "deps.edn"))]
      (if-let [aliases (:aliases conf)]
        (->> (mapcat #(get-in edn [:aliases % :extra-deps])  aliases)
             (filter-and-normalize-deps required-deps))
        (->> (:deps edn)
             (filter-and-normalize-deps required-deps))))

    ;; c.f. https://shadow-cljs.github.io/docs/UsersGuide.html#Leiningen
    ;; TODO
    (contains? shadow-edn :lein)
    #{}

    :else
    (->> (:dependencies shadow-edn)
         (filter-and-normalize-deps required-deps))))

(defn differences
  [shadow-cljs-config-path vim-iced-home-dir]
  (let [iced-deps-edn (read-edn (io/file vim-iced-home-dir "deps.edn"))
        shadow-cljs-edn (read-edn shadow-cljs-config-path)
        required-deps (->> (:deps iced-deps-edn)
                           (keep (comp #(when (not= % 'nrepl) %) first))
                           set)

        iced-dependency-set (->> (:deps iced-deps-edn)
                                 (filter-and-normalize-deps required-deps))
        shadow-dependency-set (->> shadow-cljs-edn
                                   (extract-shadow-cljs-dependency-set
                                    required-deps shadow-cljs-config-path))]
    {:dependencies (set/difference
                    iced-dependency-set
                    shadow-dependency-set)
     :middlewares (set/difference
                   (set (map symbol (:__middlewares__ iced-deps-edn)))
                   (set (get-in shadow-cljs-edn [:nrepl :middleware])))}))

(defn -main
  [args]
  (when (not= 2 (count args))
    (System/exit 1))

  (let [{:keys [dependencies middlewares]} (apply differences args)]
    (str/join
     "\n"
     (concat
      (map #(apply format "Missing dependency: %s => %s" %) dependencies)
      (map #(format "Missing middleware: %s" %) middlewares)))))

(when *command-line-args*
  (-main *command-line-args*))
