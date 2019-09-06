RESULT=0

## Vint
find . -name "*.vim" \
    | grep -v vital \
    | grep -v .vim-themis \
    | grep -v .vim-sexp \
    | grep -v .vimdoc \
    | xargs vint
if [ $? -ne 0 ]; then
    RESULT=1
fi

## cword
find autoload/iced -name "*.vim" \
    | xargs grep '<cword>' \
    | grep -v iced/nrepl/var.vim
if [ $? -ne 1 ]; then
    echo 'Do not use <cword> directly. Use iced#nrepl#var#cword()'
    RESULT=1
fi

exit $RESULT
