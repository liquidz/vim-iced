let s:save_cpo = &cpo
set cpo&vim

function! s:generate_doc(resp) abort
  if has_key(a:resp, 'ns') && has_key(a:resp, 'arglists-str')
    let name = printf('%s/%s', a:resp['ns'], a:resp['name'])
    let args = join(split(a:resp['arglists-str'], '\r\?\n'), "\n  ")
    let doc  = get(a:resp, 'doc', '')
    let text = printf("%s\n  %s\n\n  %s", name, args, doc)
    return text
  else
    echom iced#message#get('not_found')
  endif
endfunction

function! iced#nrepl#document#open(symbol) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return
  endif

  let kw = empty(a:symbol) ? expand('<cword>') : a:symbol
  call iced#nrepl#cider#info(kw, {resp -> iced#preview#view(s:generate_doc(resp))})
endfunction

function! s:one_line_doc(resp) abort
  if has_key(a:resp, 'ns')
    let name = printf('%s/%s', a:resp['ns'], a:resp['name'])
    let args = substitute(a:resp['arglists-str'], '\r\?\n', ' ', 'g')
    echo printf('%s %s', name, args)
  endif
endfunction

function! iced#nrepl#document#echo_current_form() abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return
  endif

  let current_pos = getcurpos()
  let reg_save = @@

  try
    silent normal! vi(y
    let symbol = trim(split(@@, ' ')[0])
    call iced#nrepl#cider#info(symbol, funcref('s:one_line_doc'))
  finally
    let @@ = reg_save
    call cursor(current_pos[1], current_pos[2])
  endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
