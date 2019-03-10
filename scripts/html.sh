MYSTYLE=$(cat << EOS
body {
    font-family: 'Roboto Mono', monospace;
}

p {
    margin: 0;
}

.section-header .section-link {
    visibility: hidden;
    margin-left: -1.5rem;
    padding-right: 0.5rem;
}

.section-header:hover .section-link {
    visibility: visible;
}

.constant {
    text-decoration: underline;
}

.divider {
    color: #aaa;
}

footer {
    margin-top: 2rem;
    padding: 1rem;
    background-color: #fafafa;
    text-align: right;
}
.missing-tag {
    color: red !important;
}
EOS
)

mkdir -p target/html
clojure -A:doc doc/vim-iced.txt \
    --title vim-iced \
    --css "//fonts.googleapis.com/css?family=Roboto+Mono" \
    --css "//cdn.rawgit.com/necolas/normalize.css/master/normalize.css" \
    --css "//cdn.rawgit.com/milligram/milligram/master/dist/milligram.min.css" \
    --style "$MYSTYLE" \
    --copyright "(c) Masashi Iizuka" \
    --output=target/html \
    --verbose

