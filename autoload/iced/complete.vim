let s:save_cpo = &cpo
set cpo&vim

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

function! s:ns_candidate(ns_name) abort
  return {
      \ 'word':  a:ns_name,
      \ 'kind':  s:type_to_kind_dict['namespace'],
      \ 'icase': 1,
      \}
endfunction

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

function! s:ns_var_candidates(ns_name, base, alias) abort
  let result = []
  if a:ns_name =~# '^[A-Z]'
    return result
  endif

  let resp = iced#nrepl#op#cider#sync#ns_vars(a:ns_name)
  if empty(resp) || resp['status'][0] !=# 'done'
    return []
  endif

  let dict = get(resp, 'ns-vars-with-meta', {})
  for k in keys(dict)
    if stridx(k, a:base) == 0
      let arglists = get(dict[k], 'arglists', '')
      let doc = get(dict[k], 'doc', '')
      let doc = strpart(doc, 1, len(doc)-2)
      let doc = substitute(doc, '\\n', "\n", 'g')
      let doc = '  ' . doc
      let doc = join([
            \ printf('%s/%s', a:ns_name, k),
            \ s:format_arglist(arglists),
            \ doc,
            \ ], "\n")
      call add(result, {
          \ 'candidate': (empty(a:alias) ? k : printf('%s/%s', a:alias, k)),
          \ 'arglists': [arglists],
          \ 'doc': doc,
          \ 'type': 'var',
          \ })
    endif
  endfor

  return result
endfunction

function! s:ns_alias_candidates(aliases, base) abort
  let result = []
  for alias in a:aliases
    if stridx(alias, a:base) == 0
      call add(result, {
          \ 'candidate': alias,
          \ 'type': 'namespace',
          \ })
    endif
  endfor
  return result
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

    silent exe 'normal! va(y'
    let codes = split(@@, '\r\?\n')
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

function! iced#complete#omni(findstart, base) abort
  if a:findstart
    let line = getline('.')
    let ncol = col('.')
    let s = line[0:ncol-2]
    return ncol - strlen(matchstr(s, '\k\+$')) - 1
  elseif len(a:base) > 1 && iced#nrepl#is_connected() && iced#nrepl#check_session_validity()
    let ns_name = iced#nrepl#ns#name()
    let candidates = []

    " vars in current namespace
    let tmp = s:ns_var_candidates(ns_name, a:base, '')
    if !empty(tmp)
      let candidates = candidates + tmp
    endif

    " namespace aliases
    let alias_dict = iced#nrepl#ns#alias_dict(ns_name)
    if !empty(alias_dict)
      let candidates = candidates + s:ns_alias_candidates(keys(alias_dict), a:base)
    endif

    " vars in aliased namespace
    let i = stridx(a:base, '/')
    if i != -1 && a:base[0] !=# ':'
      let org_base_ns = a:base[0:i-1]
      let base_ns = get(alias_dict, org_base_ns, org_base_ns)
      let base_sym = a:base[i+1:]
      let tmp = s:ns_var_candidates(base_ns, base_sym, org_base_ns)
      if !empty(tmp)
        let candidates = candidates + tmp
      endif
    endif

    " cider completions
    let ctx = s:context()
    let resp = iced#nrepl#op#cider#sync#complete(a:base, ns_name, ctx)
    if type(resp) == type({}) && has_key(resp, 'completions')
      let candidates = candidates + resp['completions']
    endif

    return sort(map(candidates, {_, v -> s:candidate(v)}),
          \ {a, b -> a['word'] > b['word']})
  endif

  return []
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
