find . -name "*.vim" \
  | grep -v vital \
  | grep -v .vim-themis \
  | grep -v .vim-sexp \
  | grep -v .vimdoc \
  | xargs vint
