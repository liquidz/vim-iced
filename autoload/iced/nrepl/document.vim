let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:S = s:V.import('Data.String')
let s:D = s:V.import('Data.Dict')

let s:popup_winid = -1

let s:enable_popup_one_line_document =
      \ g:iced_enable_popup_document ==# 'one-line'
      \ || g:iced_enable_popup_document ==# 'every'

let s:enable_popup_full_document =
      \ g:iced_enable_popup_document ==# 'full'
      \ || g:iced_enable_popup_document ==# 'every'

let g:iced#buffer#document#does_update_automatically =
      \ get(g:, 'iced#buffer#document#does_update_automatically', v:false)

let s:subsection_sep = '------------------------------------------------------------------------------'

function! s:popup_context(d) abort
  return extend({
        \ 'type': 'default',
        \ 'curpos': getcurpos(),
        \ }, a:d)
endfunction

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

function! s:view_doc_on_buffer(resp) abort
  let doc = s:generate_doc(a:resp)
  if !empty(doc)
    call iced#buffer#document#open(doc, 'help')
  endif
endfunction

function! s:view_doc_on_popup(resp) abort
  let doc = printf(' %s', s:generate_doc(a:resp))
  let popup = iced#di#get('popup')

  if empty(doc) || !popup.is_supported()
    return
  endif

  if s:popup_winid != -1 | call popup.close(s:popup_winid) | endif
  let s:popup_winid = popup.open(split(doc, '\r\?\n'), {
        \ 'iced_context': s:popup_context({'type': 'full document'}),
        \ 'line': line('.') + 1,
        \ 'col': col('.'),
        \ 'filetype': 'help',
        \ 'border': [],
        \ 'borderhighlight': ['Comment'],
        \ 'auto_close': v:false,
        \ 'moved': [0, &columns],
        \ })
endfunction

function! iced#nrepl#document#open(symbol) abort
  call iced#nrepl#ns#eval({_ ->
        \ iced#nrepl#var#get(a:symbol, funcref('s:view_doc_on_buffer'))
        \ })
endfunction

function! iced#nrepl#document#popup_open(symbol) abort
  if !iced#di#get('popup').is_supported()
        \ || !s:enable_popup_full_document
    return iced#nrepl#document#open(a:symbol)
  endif

  call iced#nrepl#ns#eval({_ ->
        \ iced#nrepl#var#get(a:symbol, funcref('s:view_doc_on_popup'))
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
    if popup.is_supported() && s:enable_popup_one_line_document
      if s:popup_winid != -1 | call popup.close(s:popup_winid) | endif

      let popup_opts = {
            \ 'iced_context': s:popup_context({'type': 'one-line document'}),
            \ 'line': line('.')+1,
            \ 'col': col('.'),
            \ 'filetype': 'clojure',
            \ 'border': [],
            \ 'borderhighlight': ['Comment'],
            \ 'title': name,
            \ 'auto_close': v:false,
            \ 'moved': [0, &columns],
            \ }

      let popup_args = trim(get(a:resp, 'arglists-str', ''))
      let popup_args = substitute(popup_args, '\r\?\n', " \n ", 'g')
      let popup_args = printf(' %s ', popup_args)
      let s:popup_winid = popup.open(split(popup_args, '\n'), popup_opts)
    endif

    echo iced#util#shorten(msg)
  endif
endfunction

function! iced#nrepl#document#clear_doc_popup() abort
  let popup = iced#di#get('popup')
  let context = popup.get_context(s:popup_winid)
  if !s:enable_popup_one_line_document
        \ || !popup.is_supported()
        \ || s:popup_winid == -1
        \ || get(popup.get_context(s:popup_winid), 'curpos', [-1, -1])[1] == line('.')
    return
  endif

  call popup.close(s:popup_winid)

  let s:popup_winid = -1
endfunction

function! iced#nrepl#document#current_form() abort
  let context = iced#di#get('popup').get_context(s:popup_winid)
  if !iced#nrepl#is_connected()
        \ || get(context, 'type', '') ==# 'full document'
        \ || get(context, 'curpos', []) ==# getcurpos()
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
