(ns iced.leiningen)


; function leiningen_deps_args() {
;     local deps=($@)
;
;     for s in "${deps[@]}" ; do
;         key="${s%%:*}"
;         value="${s##*:}"
;         echo -n "update-in :dependencies conj '[${key} \"${value}\"]' -- "
;     done
; }

(defn gen-deps-args
  [deps]
  )

(defn lein-using-cljs? [project-clj-content]
  (let [skip-exclusions? (atom false)
        result (atom false)]
    (->> project-clj-content
         read-string
         (filter #(= 'defproject (first %)))
         first
         (walk/postwalk
           (fn [x]
             (cond
               (and @skip-exclusions? (sequential? x) (apply = ::skip x)) (reset! skip-exclusions? false)
               @skip-exclusions? ::skip
               (= :exclusions x) (reset! skip-exclusions? true)
               (= 'org.clojure/clojurescript x) (reset! result true)
               :else x))))
    @result))
