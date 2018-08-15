let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('iced')
let s:S = s:V.import('Data.String')
let s:D = s:V.import('Data.Dict')

function! s:format_spec(x) abort
  if type(a:x) == type([])
    if a:x[0][0] ==# ':'
      return printf('[%s]', join(map(a:x, {_, v -> s:format_spec(v)}), ' '))
    else
      let fn = s:S.replace_first(a:x[0], 'clojure.spec.alpha', 's')
      let args = join(map(a:x[1:], {_, v -> s:format_spec(v)}), ' ')
      return printf('(%s %s)', fn, args)
    endif
  else
    return printf('%s', a:x)
  endif
endfunction

function! s:generate_doc(resp) abort
  if has_key(a:resp, 'status') && a:resp['status'] == ['done']
    let doc = []
    if has_key(a:resp, 'ns')
      call add(doc, printf('%s/%s', a:resp['ns'], a:resp['name']))
    else
      call add(doc, a:resp['name'])
    endif

    if has_key(a:resp, 'arglists-str')
      call add(doc, printf('  %s', join(split(a:resp['arglists-str'], '\r\?\n'), "\n  ")))
    endif
    let docs = split(get(a:resp, 'doc', iced#message#get('no_document')), '\r\?\n')
    call add(doc, printf('  %s', docs[0]))
    for doc_line in docs[1:]
      call add(doc, doc_line)
    endfor

    if has_key(a:resp, 'spec')
      call add(doc, '')
      call add(doc, a:resp['spec'][0])
      let specs = s:D.from_list(a:resp['spec'][1:])
      for k in keys(specs)
        let v = specs[k]
        if k ==# ':args' || k ==# ':ret'
          call add(doc, printf('%7s  %s', k, s:format_spec(v)))
        endif
      endfor
    endif

    return (empty(doc) ? '' : join(doc, "\n"))
  else
    echom iced#message#get('not_found')
  endif
endfunction

function! s:view_doc(resp) abort
  let doc = s:generate_doc(a:resp)
  call iced#preview#view(doc)
  call iced#preview#set_type('document')
endfunction

function! iced#nrepl#document#open(symbol) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return
  endif

  let kw = empty(a:symbol) ? expand('<cword>') : a:symbol
  call iced#nrepl#cider#info(kw, funcref('s:view_doc'))
endfunction

function! s:one_line_doc(resp) abort
  if iced#preview#type() ==# 'document'
    call iced#preview#view(s:generate_doc(a:resp))
  else
    if has_key(a:resp, 'ns')
      let name = printf('%s/%s', a:resp['ns'], a:resp['name'])
      let arglists = get(a:resp, 'arglists-str', '')
      let args = substitute(arglists, '\r\?\n', ' ', 'g')
      echo printf('%s %s', name, args)
    endif
  endif
endfunction

function! iced#nrepl#document#current_form() abort
  if !iced#nrepl#is_connected()
    return
  endif

  let view = winsaveview()
  let reg_save = @@

  try
    silent normal! vi(y
    let symbol = trim(split(@@, ' ')[0])
    call iced#nrepl#cider#info(symbol, funcref('s:one_line_doc'))
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
