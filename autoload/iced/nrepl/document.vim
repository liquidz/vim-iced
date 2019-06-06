let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:S = s:V.import('Data.String')
let s:D = s:V.import('Data.Dict')

let s:document_popup_winid = -1
let s:document_target_line = -1

let g:iced#buffer#document#does_update_automatically =
      \ get(g:, 'iced#buffer#document#does_update_automatically', v:false)

let s:subsection_sep = '------------------------------------------------------------------------------'

function! s:generate_javadoc(resp) abort
  let doc = []
  let title = (has_key(a:resp, 'member'))
        \ ? printf('%s/%s', a:resp['class'], a:resp['member'])
        \ : a:resp['class']
  call add(doc, printf('*%s*', title))

  if has_key(a:resp, 'arglists-str')
    call add(doc, printf('  %s', join(split(a:resp['arglists-str'], '\r\?\n'), "\n  ")))
  endif

  let docs = split(get(a:resp, 'doc', iced#message#get('no_document')), '\r\?\n')
  call add(doc, printf('  %s', docs[0]))

  if has_key(a:resp, 'returns')
    call add(doc, '')
    call add(doc, s:subsection_sep)
    call add (doc, '*Returns*')
    call add (doc, printf('  %s', a:resp['returns']))
  endif

  if has_key(a:resp, 'javadoc')
    call add(doc, '')
    call add(doc, a:resp['javadoc'])
  endif

  return doc
endfunction

function! s:add_indent(n, s) abort
  let spc = ''
  for _ in range(a:n) | let spc = spc . ' ' | endfor
  return substitute(a:s, '\r\?\n', "\n".spc, 'g')
endfunction

function! s:generate_cljdoc(resp) abort
  let doc = []
  if !has_key(a:resp, 'name') | return doc | endif

  let title = (has_key(a:resp, 'ns'))
        \ ? printf('%s/%s', a:resp['ns'], a:resp['name'])
        \ : a:resp['name']
  call add(doc, printf('*%s*', title))

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
    call add(doc, s:subsection_sep)
    call add(doc, printf('*%s*', a:resp['spec'][0]))
    let specs = s:D.from_list(a:resp['spec'][1:])
    for k in [':args', ':ret']
      if !has_key(specs, k) | continue | endif

      let v = specs[k]
      let formatted = iced#nrepl#spec#format(v)
      let formatted = s:add_indent(9, formatted)
      call add(doc, printf('  %-5s  %s', k, formatted))
    endfor
  endif

  return doc
endfunction

function! s:generate_doc(resp) abort
  if !has_key(a:resp, 'status') || a:resp['status'] != ['done']
    call iced#message#error('not_found')
    return ''
  endif

  let doc = (has_key(a:resp, 'javadoc')
      \ ? s:generate_javadoc(a:resp)
      \ : s:generate_cljdoc(a:resp))
  return (empty(doc) ? '' : join(doc, "\n"))
endfunction

function! s:view_doc(resp) abort
  let doc = s:generate_doc(a:resp)
  if !empty(doc)
    call iced#buffer#document#open(s:generate_doc(a:resp), 'help')
  endif
endfunction

function! iced#nrepl#document#open(symbol) abort
  call iced#nrepl#ns#eval({_ ->
        \ iced#nrepl#var#get(a:symbol, funcref('s:view_doc'))
        \ })
endfunction

function! s:one_line_doc(resp) abort
  if iced#buffer#document#is_visible() && g:iced#buffer#document#does_update_automatically
    let doc = s:generate_doc(a:resp)
    if !empty(doc)
      call iced#buffer#document#update(doc, 'help')
    endif
  else
    let name = ''
    let args = ''
    let msg = ''
    if has_key(a:resp, 'javadoc')
      let name = (has_key(a:resp, 'member'))
            \ ? printf('%s/%s', a:resp['class'], a:resp['member'])
            \ : a:resp['class']
      let name = (has_key(a:resp, 'returns'))
            \ ? printf('%s %s', a:resp['returns'], name)
            \ : name
      let args = substitute(get(a:resp, 'arglists-str', ''), '\r\?\n', ' ', 'g')
      let msg =  printf('%s %s', name, args)
    elseif has_key(a:resp, 'ns') && has_key(a:resp, 'name')
      let name = printf('%s/%s', a:resp['ns'], a:resp['name'])
      let args = substitute(get(a:resp, 'arglists-str', ''), '\r\?\n', ' ', 'g')
      let msg = printf('%s %s', name, args)
    endif

    if empty(msg) | return | endif

    let popup = iced#di#get('popup')
    if popup.is_supported() && g:iced#buffer#document#does_use_popup
      if s:document_popup_winid != -1 | call popup.close(s:document_popup_winid) | endif

      let popup_opts = {
            \ 'line': line('.')+1,
            \ 'col': col('.'),
            \ 'filetype': 'clojure',
            \ 'border': [],
            \ 'title': name,
            \ 'auto_close': v:false,
            \ }

      let s:document_popup_winid = popup.open([
            \ printf(' %s ', args),
            \ ], popup_opts)
      let s:document_target_line = line('.')
    endif

    echo iced#util#shorten(msg)
  endif
endfunction

function! iced#nrepl#document#clear_one_line_doc_popup() abort
  let popup = iced#di#get('popup')
  if !g:iced#buffer#document#does_use_popup
        \ || !popup.is_supported()
        \ || s:document_popup_winid == -1
        \ || s:document_target_line == line('.')
    return
  endif

  call popup.close(s:document_popup_winid)

  let s:document_popup_winid = -1
  let s:document_target_line = -1
endfunction

function! iced#nrepl#document#current_form() abort
  if !iced#nrepl#is_connected()
    return
  endif

  let ns_name = iced#nrepl#ns#name()
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
        call iced#nrepl#var#get(symbol, funcref('s:one_line_doc'))
      endif
    endif
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
