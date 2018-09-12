let s:save_cpo = &cpo
set cpo&vim

let s:type_dict = {
      \ 'namespace': 'n',
      \ 'function': 'f',
      \ }

function! s:accept(mode, v) abort
  let [_name, _type, path, pos] = split(a:v, "\t")
  let [line_str, column_str] = split(pos, ':')

  let cmd = ':edit'
  if a:mode ==# 'v'
    let cmd = ':split'
  elseif a:mode ==# 't'
    let cmd = ':tabedit'
  endif
  exe printf('%s %s', cmd, path)

  call cursor(str2nr(line_str), str2nr(column_str))
  normal! zz
endfunction

function! s:format_candidate(candidate) abort
  return printf("%s\t%s\t%s\t%d:%d",
        \ a:candidate['name'],
        \ s:type_dict[a:candidate['type']],
        \ a:candidate['file'],
        \ a:candidate['line'], a:candidate['column'])
endfunction

function! s:everywhere(candidates) abort
  call ctrlp#iced#start({
        \ 'candidates': map(a:candidates, {_, v -> s:format_candidate(v)}),
        \ 'accept': funcref('s:accept')
        \ })
endfunction

function! iced#nrepl#everywhere#search() abort
  call iced#nrepl#iced#everywhere(funcref('s:everywhere'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
