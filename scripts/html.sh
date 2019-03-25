MYSTYLE=$(cat << EOS
body {
    font-family: 'Roboto Mono', monospace;
}
p {
    margin: 0;
}

header, footer {
    padding: 1rem;
    background-color: #fafafa;
}

header {
    margin-bottom: 1rem;
}

header:after {
    content: "";
    clear: both;
    display: table;
}

header h1.title {
    font-size: 16px;
    line-height: 25.6px;
    margin: 0;
    float: left;
}

header nav.files {
    float: left;
    margin-left: 5rem;
    position: relative;
}

header nav.files input#current-file {
    display: none;
}

header nav.files input#current-file + label {
    display: inline;
    color: #aaa;
    font-weight: 1;
    margin: 0;
}

header nav.files input#current-file + label:before {
    font-family: 'Font Awesome 5 Free';
    content: '\f0da';
    font-weight: 900;
    padding-right: 0.5rem;
}

header nav.files input#current-file:checked + label:before {
    font-family: 'Font Awesome 5 Free';
    content: '\f0d7';
    font-weight: 900;
    padding-right: 0.5rem;
}

header nav.files input#current-file:checked + label + ul {
    opacity: 1;
    height: auto;
    z-index: 999;
    background-color: white;
    border: 1px solid #ccc;
    padding: 1rem;
}

header nav.files ul {
    opacity: 0;
    height: 0;
    z-index: -1;
    width: 200%;
    position: absolute;
    top: 1.5em;
    left: 0;
    list-style-type: none;
}

header nav.files ul li {
    margin: 0;
    padding: 0.5rem;
}

header nav.files ul li.active:before {
    font-family: 'Font Awesome 5 Free';
    content: '\f00c';
    font-weight: 900;
    padding-right: 0.5rem;
}

header p.edit-link {
    float: right;
}

header p.edit-link a:before {
    font-family: 'Font Awesome 5 Brands';
    content: '\f09b';
    padding-right: 0.5rem;
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

.missing-tag {
    color: red !important;
}

footer {
    margin-top: 2rem;
    text-align: right;
}
EOS
)

mkdir -p target/html
clojure -A:doc doc/*.txt \
    --title 'vim-iced help' \
    --css '//fonts.googleapis.com/css?family=Roboto+Mono' \
    --css '//cdn.rawgit.com/necolas/normalize.css/master/normalize.css' \
    --css '//cdn.rawgit.com/milligram/milligram/master/dist/milligram.min.css' \
    --css '//use.fontawesome.com/releases/v5.7.2/css/all.css' \
    --style "$MYSTYLE" \
    --copyright '(c) Masashi Iizuka' \
    --blob 'https://github.com/liquidz/vim-iced/blob/master/doc' \
    --output=target/html \
    --verbose

