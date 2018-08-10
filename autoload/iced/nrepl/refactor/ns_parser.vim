let s:save_cpo = &cpo
set cpo&vim

let s:ns = 'refactor-nrepl.ns.ns-parser'

function! iced#nrepl#refactor#ns_parser#aliases(code) abort
  let code = '(do'
      \ . printf('(require ''%s)', s:ns)
      \ . printf('(%s/aliases (%s/get-libspecs ''%s))', s:ns, s:ns, a:code)
      \ . ')'

  return iced#nrepl#sync#send({
      \ 'op': 'eval',
      \ 'code': code,
      \ 'session': iced#nrepl#clj_session(),
      \ })
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
