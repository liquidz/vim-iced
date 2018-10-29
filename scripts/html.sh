rm -rf target/html
mkdir -p target/html/doc
cp doc/vim-iced.txt target/html/doc
(cd target/html/doc && vim -eu ../../../.vimdoc/tools/buildhtml.vim -c "qall!")
sed -i '1,4d' target/html/doc/vim-iced.html
sed -i 's/vim-iced\.html/index\.html/g' target/html/doc/vim-iced.html
cat doc/.head.html target/html/doc/vim-iced.html doc/.foot.html > target/index.html
