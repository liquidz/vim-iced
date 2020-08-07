let s:save_cpo = &cpoptions
set cpoptions&vim

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

let g:iced#buffer#document#subsection_sep =
      \ get(g:, 'iced#buffer#document#subsection_sep', '------------------------------------------------------------------------------')

function! s:popup_context(d) abort
  return extend({
        \ 'type': 'default',
        \ 'curpos': getcurpos(),
        \ }, a:d)
endfunction

function! s:generate_javadoc(resp) abort " {{{
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
    call add(doc, g:iced#buffer#document#subsection_sep)
    call add (doc, '*Returns*')
    call add (doc, printf('  %s', a:resp['returns']))
  endif

  if has_key(a:resp, 'javadoc')
    call add(doc, '')
    call add(doc, a:resp['javadoc'])
  endif

  return doc
endfunction " }}}

function! s:generate_cljdoc(resp) abort " {{{
  let doc = []
  if !has_key(a:resp, 'name') | return doc | endif

  let title = (has_key(a:resp, 'ns'))
        \ ? printf('%s/%s', a:resp['ns'], a:resp['name'])
        \ : a:resp['name']
  call add(doc, printf('*%s*', title))

  if has_key(a:resp, 'arglists-str')
    call add(doc, printf('  %s', join(split(a:resp['arglists-str'], '\r\?\n'), "\n  ")))
  endif
  let doc_str = get(a:resp, 'doc', iced#message#get('no_document'))
  let doc_str = (type(doc_str) == v:t_string) ? doc_str : iced#message#get('no_document')
  let docs = split(doc_str, '\r\?\n')
  call add(doc, printf('  %s', docs[0]))
  for doc_line in docs[1:]
    call add(doc, doc_line)
  endfor

  if has_key(a:resp, 'spec')
    call add(doc, '')
    call add(doc, g:iced#buffer#document#subsection_sep)
    call add(doc, printf('*%s*', a:resp['spec'][0]))
    let specs = s:D.from_list(a:resp['spec'][1:])
    for k in [':args', ':ret']
      if !has_key(specs, k) | continue | endif

      let v = specs[k]
      let formatted = iced#nrepl#spec#format(v)
      let formatted = iced#util#add_indent(9, formatted)
      call add(doc, printf('  %-5s  %s', k, formatted))
    endfor
  endif

  if has_key(a:resp, 'see-also')
    call add(doc, '')
    call add(doc, g:iced#buffer#document#subsection_sep)
    call add(doc, '*see-also*')
    for name in a:resp['see-also']
      call add(doc, printf(' - %s', name))
    endfor
  endif

  return doc
endfunction " }}}

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

function! s:generate_doc_by_meta(symbol) abort
  let code = iced#socket_repl#document#code(a:symbol)
  let opt = {'ns': iced#nrepl#ns#name_by_buf()}
  return iced#promise#call('iced#nrepl#eval', [code, opt])
        \.then({resp -> get(resp, 'value', '')})
        \.then({value -> substitute(value, '\(^"\|"$\)', '', 'g')})
        \.then({value -> substitute(trim(value), '\\n', "\n", 'g')})
endfunction

function! s:view_doc_on_buffer(doc) abort
  if !empty(a:doc)
    call iced#buffer#document#open(a:doc, 'help')
  endif
endfunction

function! s:view_doc_on_popup(doc) abort
  let popup = iced#system#get('popup')
  if empty(a:doc) || !popup.is_supported()
    return
  endif

  let doc = printf(' %s', a:doc)
  if s:popup_winid != -1 | call popup.close(s:popup_winid) | endif
  try
    let s:popup_winid = popup.open(split(doc, '\r\?\n'), {
          \ 'iced_context': s:popup_context({'type': 'full document'}),
          \ 'line': 'near-cursor',
          \ 'col': col('.'),
          \ 'filetype': 'help',
          \ 'border': [],
          \ 'borderhighlight': ['Comment'],
          \ 'auto_close': v:false,
          \ 'moved': [0, &columns],
          \ })
  catch
    call iced#message#warning('popup_error', string(v:exception))
    " fallback to iced#nrepl#document#open
    call s:view_doc_on_buffer(a:doc)
  endtry
endfunction

function! iced#nrepl#document#open(symbol) abort
  if iced#nrepl#is_supported_op('info')
    if !iced#nrepl#check_session_validity() | return | endif
    return iced#promise#call('iced#nrepl#var#get', [a:symbol])
          \.then({resp -> s:generate_doc(resp)})
          \.then(funcref('s:view_doc_on_buffer'))
  else
    " Use simple document by metadata when there is no `info` op.
    return s:generate_doc_by_meta(a:symbol)
          \.then(funcref('s:view_doc_on_buffer'))
  endif
endfunction

function! iced#nrepl#document#popup_open(symbol) abort
  if !iced#system#get('popup').is_supported()
        \ || !s:enable_popup_full_document
    return iced#nrepl#document#open(a:symbol)
  endif

  if iced#nrepl#is_supported_op('info')
    if !iced#nrepl#check_session_validity() | return | endif
    return iced#promise#call('iced#nrepl#var#get', [a:symbol])
          \.then({resp -> s:generate_doc(resp)})
          \.then(funcref('s:view_doc_on_popup'))
  else
    " Use simple document by metadata when there is no `info` op.
    return s:generate_doc_by_meta(a:symbol)
          \.then({value -> substitute(value, "\n", "\n  ", 'g')})
          \.then(funcref('s:view_doc_on_popup'))
  endif
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

    let popup = iced#system#get('popup')
    if popup.is_supported()
          \ && s:enable_popup_one_line_document

      if s:popup_winid != -1 | call popup.close(s:popup_winid) | endif

      let popup_args = trim(get(a:resp, 'arglists-str', ''))
      let popup_args = substitute(popup_args, '\r\?\n', " \n ", 'g')
      let popup_args = printf(' %s ', popup_args)
      let popup_args = split(popup_args, '\n')

      let max_len = max(map(copy(popup_args), {_, v -> len(v)}))
      let fmt = printf('%%%ds', max_len)
      call map(popup_args, {_, v -> printf(fmt, v)})

      let lnum = winline() - len(popup_args)
      let popup_opts = {
            \ 'iced_context': s:popup_context({'type': 'one-line document', 'name': name}),
            \ 'line': (lnum < 0) ? winline() + 1 : lnum,
            \ 'col': 'right',
            \ 'auto_close': v:false,
            \ 'moved': [0, &columns],
            \ 'highlight': 'Title',
            \ 'wrap': v:false,
            \ }

      try
        let s:popup_winid = popup.open(popup_args, popup_opts)
      catch
        call iced#message#warning('popup_error', string(v:exception))
      endtry
    endif

    call iced#system#get('io').echo(iced#util#shorten(msg))
  endif
endfunction

function! iced#nrepl#document#current_form() abort
  if !iced#nrepl#is_connected()
        \ || !iced#nrepl#is_supported_op('info')
    return
  endif

  let popup = iced#system#get('popup')
  let context = popup.get_context(s:popup_winid)
  if !iced#nrepl#is_connected()
        \ || !iced#nrepl#check_session_validity(v:false)
        \ || get(context, 'type', '') ==# 'full document'
        \ || get(context, 'curpos', []) ==# getcurpos()
    return
  endif

  let view = winsaveview()
  let code = ''
  let code_lnum = 0
  let reg_save = @@
  try
    let @@ = ''
    silent normal! vi(y
    let code_lnum = line('.')
    let code = trim(@@)
  finally
    silent exe "normal! \<Esc>"
    let @@ = reg_save
    call winrestview(view)
  endtry

  let distance = line('.') - code_lnum
  if empty(code) || distance > g:iced_max_distance_for_auto_document
    return
  endif

  let symbol = trim(split(code, ' ')[0])
  if stridx(symbol, ':') != 0
    call iced#nrepl#var#get(symbol, funcref('s:one_line_doc'))
  endif
endfunction

let s:last_usecase_info = {}

function! s:show_usecase(info) abort
  if !has_key(a:info, 'index')
        \ || !has_key(a:info, 'refs')
        \ || !has_key(a:info, 'ns')
        \ || !has_key(a:info, 'symbol')
    return iced#message#error('invalid_format', a:info)
  endif

  let index = a:info['index']
  let ref = a:info['refs'][index]
  let ns = a:info['ns']
  let symbol = a:info['symbol']

  let reg_save = @@
  try
    " Open temporary buffer with ref file contents
    call iced#buffer#temporary#begin()
    call iced#system#get('ex_cmd').silent_exe(printf(':read %s', ref['file']))

    " Detect ns alias in the ref file
    let ref_ns = iced#nrepl#ns#name()
    call iced#promise#sync('iced#nrepl#ns#require', [ref_ns])
    let resp = iced#nrepl#op#cider#sync#ns_aliases(ref_ns)
    if !has_key(resp, 'ns-aliases') | return iced#message#info('not_found') | endif

    let alias = keys(filter(resp['ns-aliases'], {_, v -> v ==# ns}))

    " Search ref's concrete position
    let names = [
          \ empty(alias) ? symbol : printf('%s/%s', alias[0], symbol),
          \ printf('%s/%s', ns, symbol),
          \ ]
    let pos = [0, 0]

    call cursor(ref['line']+1, 1)
    for name in names
      if pos != [0, 0] | break | endif

      let pos = searchpos(printf('(%s ', name), 'n')
      if pos == [0, 0]
        let pos = searchpos(printf("(%s\n", name), 'n')
      endif
      if pos == [0, 0]
        let pos = searchpos(printf('(%s)', name), 'n')
      endif
    endfor

    if pos == [0, 0] | return iced#message#info('not_found') | endif
    call cursor(pos[0], pos[1])

    silent normal! vaby
    let texts = join([
          \ printf(';; Use case for %s/%s (%d/%d)', ns, symbol, index+1, len(a:info['refs'])),
          \ printf(';; %s:%d:%d', ref['file'], pos[0], pos[1]),
          \ iced#util#del_indent(pos[1]-1, @@),
          \ ], "\n")
    call iced#buffer#document#open(texts, 'clojure')
    call cursor(1, 1)
  finally
    call iced#buffer#temporary#end()
    let @@ = reg_save
  endtry
endfunction

function! s:find_usecase(var_resp) abort
  if !has_key(a:var_resp, 'ns') || !has_key(a:var_resp, 'name')
    return iced#message#error('not_found')
  endif

  let ns = a:var_resp['ns']
  let name = a:var_resp['name']
  let resp = iced#promise#sync('iced#nrepl#op#cider#fn_refs', [ns, name])

  let refs = filter(copy(resp['fn-refs']), {_, v -> filereadable(v['file'])})
  if empty(refs) | return iced#message#info('not_found') | endif

  let s:last_usecase_info = {
        \ 'refs': refs,
        \ 'ns': ns,
        \ 'symbol': name,
        \ 'index': 0,
        \ }

  call s:show_usecase(s:last_usecase_info)
endfunction

function! iced#nrepl#document#usecase(symbol) abort
  return iced#nrepl#var#get(a:symbol, funcref('s:find_usecase'))
endfunction

function! s:move_usecase(i) abort
  if empty(s:last_usecase_info)
    return iced#message#error('no_last_use_cases')
  endif

  let ref_count = len(s:last_usecase_info['refs'])
  if ref_count == 1
    return iced#message#warning('no_more_use_cases')
  endif

  let new_index = s:last_usecase_info['index'] + a:i
  if new_index < 0
    let new_index = ref_count-1
  elseif new_index >= ref_count
    let new_index = 0
  endif

  let s:last_usecase_info['index'] = new_index
  call s:show_usecase(s:last_usecase_info)
endfunction

function! iced#nrepl#document#next_usecase() abort
  call s:move_usecase(1)
endfunction

function! iced#nrepl#document#prev_usecase() abort
  call s:move_usecase(-1)
endfunction

function! iced#nrepl#document#close() abort
  if s:popup_winid != -1
    call iced#system#get('popup').close(s:popup_winid)
    let s:popup_winid = -1
  endif

  call iced#buffer#document#close()
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
" vim:fdm=marker:fdl=0
