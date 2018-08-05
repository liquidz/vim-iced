let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('iced')
let s:L = s:V.import('Data.List')

" 'spec': [
"     'clojure.spec.alpha/fspec',
"     ':args', ['clojure.spec.alpha/cat', ':x', ':foo.core/x'],
"     ':ret', 'clojure.core/nil?', ':fn', ''
"  ],

function! s:generate_doc(resp) abort
  echom printf('FIXME; %s', a:resp)
  if has_key(a:resp, 'status') && a:resp['status'] == ['done']
    let doc = []
    call add(doc, printf('%s/%s', a:resp['ns'], a:resp['name']))
    if has_key(a:resp, 'arglists-str')
      let args = join(split(a:resp['arglists-str'], '\r\?\n'), "\n  ")
      call add(doc, '  ' . args)
    endif

    if has_key(a:resp, 'spec')
      call add(doc, '')
      call add(doc, a:resp['spec'][0])
      let specs = a:resp['spec'][1:]
      while !empty(specs)
        let k = s:L.shift(specs)
        let v = s:L.shift(specs)

        if k ==# ':args'
          call add(doc, k)
          for x in v[1:]
            call add(doc, '  ' . x)
          endfor
        elseif k ==# ':ret'
          call add(doc, k)
          call add(doc, '  ' . v)
        endif
      endwhile
    endif

    call add(doc, '')
    call add(doc, 'doc')
    call add(doc, '  ' . get(a:resp, 'doc', ''))
    return join(doc, "\n")
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
