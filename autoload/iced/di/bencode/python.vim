let s:save_cpo = &cpo
set cpo&vim

python3 import vim
py3file <sfile>:h:h:h:h:h/python/bencode.py

function! s:decode_via_python(s) abort
  let ret = ''
  python3 <<EOT
ret = iced_bencode_decode(str(vim.eval('a:s')))
cmd = 'let ret = %s' % (iced_vim_repr(ret))
vim.command(cmd)
EOT
  if type(ret) == v:t_string && ret ==# '__FAILED__'
    throw 'Failed to parse bencode.'
  endif
  return ret
endfunction

function! iced#di#bencode#python#build() abort
  let bencode = iced#di#bencode#vim#build()
  let bencode['decode'] = funcref('s:decode_via_python')
  return bencode
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
