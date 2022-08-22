let s:save_cpo = &cpoptions
set cpoptions&vim

let g:iced#nrepl#complete#ignore_context = get(g:, 'iced#nrepl#complete#ignore_context', v:false)

let s:type_to_kind_dict = {
      \ 'class':         'c',
      \ 'field':         'i',
      \ 'function':      'f',
      \ 'keyword':       'k',
      \ 'local':         'l',
      \ 'macro':         'm',
      \ 'method':        'f',
      \ 'namespace':     'n',
      \ 'resource':      'r',
      \ 'special-form':  's',
      \ 'static-field':  'i',
      \ 'static-method': 'f',
      \ 'var':           'v',
      \ }

function! s:format_arglist(arglist) abort
  if stridx(a:arglist, '(quote ') != -1
    return strpart(a:arglist, 7, len(a:arglist)-8)
  endif
  return a:arglist
endfunction

function! s:candidate(c) abort
  let arglists = copy(get(a:c, 'arglists', []))
  let arglists = map(arglists, {_, v -> s:format_arglist(v)})
  let doc = get(a:c, 'doc')
  if empty(doc)
    let doc = ''
  endif

  return {
      \ 'word': a:c['candidate'],
      \ 'kind': get(s:type_to_kind_dict, get(a:c, 'type', 'var')),
      \ 'menu': empty(arglists) ? '' : join(arglists, ' '),
      \ 'info': doc,
      \ 'icase': 1,
      \}
endfunction

function! s:candidates(resp) abort
  let candidates = (type(a:resp) == v:t_dict && has_key(a:resp, 'completions'))
        \ ? copy(a:resp['completions'])
        \ : []
  return sort(map(candidates, {_, v -> s:candidate(v)}),
        \ {a, b -> a['word'] > b['word']})
endfunction

" c.f. https://github.com/alexander-yakushev/compliment/wiki/Context
function! s:context() abort
  let view = winsaveview()
  let reg_save = @@

  try
    " vim-sexp: move to top
    silent exe "normal \<Plug>(sexp_move_to_prev_top_element)"

    let nrow = view['lnum'] - line('.')
    let ncol = view['col'] + 1

    let codes = split(iced#paredit#get_outer_list_raw(), '\r\?\n')
    let codes[nrow] = printf('%s__prefix__%s', codes[nrow][0:ncol-2], codes[nrow][ncol-1:])
    return join(codes, "\n")
  catch /E684:/
    " index out of range
    return ''
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

function! iced#nrepl#complete#candidates(base, callback) abort
  if empty(a:base) || !iced#nrepl#is_connected() || !iced#nrepl#check_session_validity(v:false)
    call a:callback([])
    return v:true
  endif

  if iced#nrepl#is_supported_op('complete')
    " cider-nrepl
    call iced#nrepl#op#cider#complete(
        \ a:base,
        \ iced#nrepl#ns#name(),
        \ (g:iced#nrepl#complete#ignore_context) ? '' : s:context(),
        \ {resp -> a:callback(s:candidates(resp))})
  elseif iced#nrepl#is_supported_op('completions')
    " nrepl
    call iced#nrepl#send({
      \ 'op': 'completions',
      \ 'id': iced#nrepl#id(),
      \ 'session': iced#nrepl#current_session(),
      \ 'prefix': a:base,
      \ 'ns': iced#nrepl#ns#name(),
      \ 'callback': {resp -> a:callback(s:candidates(resp))}})
  else
    call a:callback([])
    return v:true
  endif

  return v:true
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
