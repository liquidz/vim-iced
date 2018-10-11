let s:save_cpo = &cpo
set cpo&vim

python3 import vim
py3file <sfile>:h:h:h:h:h/python/bencode.py
let s:decoder = {}

function! s:decoder.decode(s) abort
  let ret = ''
  python3 <<EOT
ret = iced_bencode_decode(str(vim.eval('a:s')))
cmd = 'let ret = %s' % (iced_vim_repr(ret))
vim.command(cmd)
EOT
  if type(ret) == 1 && ret ==# '__FAILED__'
    throw 'Failed to parse bencode.'
  endif
  return ret
endfunction

function! iced#nrepl#bencode#python#new() abort
  return s:decoder
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
