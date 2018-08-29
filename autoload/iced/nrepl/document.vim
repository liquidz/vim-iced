let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
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

function! s:generate_javadoc(resp) abort
  let doc = []
  call add(doc, printf('# %s/%s', a:resp['class'], a:resp['member']))

  if has_key(a:resp, 'arglists-str')
    call add(doc, printf('  %s', join(split(a:resp['arglists-str'], '\r\?\n'), "\n  ")))
  endif

  let docs = split(get(a:resp, 'doc', iced#message#get('no_document')), '\r\?\n')
  call add(doc, printf('  %s', docs[0]))

  if has_key(a:resp, 'returns')
    call add(doc, '')
    call add (doc, '## Returns')
    call add (doc, printf('  %s', a:resp['returns']))
  endif

  return doc
endfunction

function! s:generate_cljdoc(resp) abort
  let doc = []
  if !has_key(a:resp, 'name') | return doc | endif

  if has_key(a:resp, 'ns')
    call add(doc, printf('# %s/%s', a:resp['ns'], a:resp['name']))
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
    call add(doc, printf('## %s', a:resp['spec'][0]))
    let specs = s:D.from_list(a:resp['spec'][1:])
    for k in keys(specs)
      let v = specs[k]
      if k ==# ':args' || k ==# ':ret'
        call add(doc, printf('%7s  %s', k, s:format_spec(v)))
      endif
    endfor
  endif

  return doc
endfunction

function! s:generate_doc(resp) abort
  if !has_key(a:resp, 'status') || a:resp['status'] != ['done']
    echom iced#message#get('not_found')
    return ''
  endif

  let doc = (has_key(a:resp, 'javadoc')
      \ ? s:generate_javadoc(a:resp)
      \ : s:generate_cljdoc(a:resp))
  return (empty(doc) ? '' : join(doc, "\n"))
endfunction

function! s:view_doc(resp) abort
  call iced#buffer#document#open(s:generate_doc(a:resp))
endfunction

function! s:expand_ns_alias(symbol) abort
  let i = stridx(a:symbol, '/')
  if i == -1 || a:symbol[0] ==# ':'
    return a:symbol
  endif

  let alias_dict = iced#nrepl#ns#alias#dict_from_code(iced#nrepl#ns#get())
  let ns = a:symbol[0:i-1]
  let ns = get(alias_dict, ns, ns)

  return printf('%s/%s', ns, strpart(a:symbol, i+1))
endfunction

function! iced#nrepl#document#open(symbol) abort
  if !iced#nrepl#is_connected()
    echom iced#message#get('not_connected')
    return
  endif

  let symbol = empty(a:symbol) ? expand('<cword>') : a:symbol
  if iced#nrepl#current_session_key() ==# 'cljs'
    let symbol = s:expand_ns_alias(symbol)
  endif

  call iced#nrepl#cider#info(symbol, funcref('s:view_doc'))
endfunction

function! s:one_line_doc(resp) abort
  if iced#buffer#document#is_visible()
    let doc = s:generate_doc(a:resp)
    if !empty(doc)
      call iced#buffer#document#update(doc)
    endif
  else
    if has_key(a:resp, 'javadoc')
      let name =  printf('%s/%s', a:resp['class'], a:resp['member'])
      let args = substitute(get(a:resp, 'arglists-str', ''), '\r\?\n', ' ', 'g')
      echo printf('%s %s %s', a:resp['returns'], name, args)
    elseif has_key(a:resp, 'ns') && has_key(a:resp, 'name')
      let name = printf('%s/%s', a:resp['ns'], a:resp['name'])
      let args = substitute(get(a:resp, 'arglists-str', ''), '\r\?\n', ' ', 'g')
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
    let @@ = ''
    silent normal! vi(y
    let code = trim(@@)
    if empty(code)
      exe "normal! \<Esc>"
    else
      let symbol = trim(split(code, ' ')[0])
      if stridx(symbol, ':') != 0
        if iced#nrepl#current_session_key() ==# 'cljs'
          let symbol = s:expand_ns_alias(symbol)
        endif
        call iced#nrepl#cider#info(symbol, funcref('s:one_line_doc'))
      endif
    endif
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
