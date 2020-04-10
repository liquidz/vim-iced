let s:save_cpo = &cpoptions
set cpoptions&vim

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
  let arglists = get(a:c, 'arglists', [])
  let arglists = map(arglists, {_, v -> s:format_arglist(v)})
  let doc = get(a:c, 'doc', '')
  return {
      \ 'word': a:c['candidate'],
      \ 'kind': get(s:type_to_kind_dict, a:c['type']),
      \ 'menu': empty(arglists) ? '' : join(arglists, ' '),
      \ 'info': doc,
      \ 'icase': 1,
      \}
endfunction


function! s:candidates(resp) abort
  let candidates = (type(a:resp) == v:t_dict && has_key(a:resp, 'completions'))
        \ ? a:resp['completions']
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
  if empty(a:base) || !iced#nrepl#is_connected() || !iced#nrepl#check_session_validity()
    return a:callback([])
  endif

  call iced#nrepl#op#cider#complete(
        \ a:base,
        \ iced#nrepl#ns#name(),
        \ s:context(),
        \ {resp -> a:callback(s:candidates(resp))})
  return v:true
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
