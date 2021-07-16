let s:save_cpo = &cpoptions
set cpoptions&vim

let g:iced#nrepl#source#finding_max_depth
      \ = get(g:, 'iced#nrepl#source#finding_max_depth', 3)

"" s:__fetch_source {{{
function! s:__extract_source(resp) abort
  let path = get(a:resp, 'file', '')
  if empty(path) | return '' | endif

  let code = ''
  let reg_save = @@
  try
    call iced#buffer#temporary#begin()
    call iced#system#get('ex_cmd').silent_exe(printf(':read %s', path))
    call cursor(a:resp['line']+1, get(a:resp, 'column', 0))
    silent normal! vaby
    let code = @@
  finally
    let @@ = reg_save
    call iced#buffer#temporary#end()
  endtry

  return code
endfunction

function! s:__fetch_source(symbol) abort
  return iced#promise#call('iced#nrepl#var#get', [a:symbol])
        \.then({resp -> (empty(get(resp, 'file', '')))
        \               ? iced#promise#reject(iced#message#get('not_found'))
        \               : s:__extract_source(resp)})
endfunction
" }}}

"" s:__fetch_definition {{{
function! s:__format_definition_codes(level, result, resp) abort
  if type(a:resp) == v:t_string
    return iced#promise#resolve(printf('%s%s', join(a:result, "\n"), a:resp))
  endif

  let res = copy(a:result)
  let definition = get(a:resp, 'definition', {})
  let lbeg = definition['line-beg']
  let lend = definition['line-end']

  let user_dir = iced#nrepl#system#user_dir()
  let file = printf(';; file: %s:%s',
        \ strpart(definition['file'], len(user_dir)),
        \ (lbeg == lend) ? string(lbeg) : printf('%d - %d', lbeg, lend),
        \ )

  " Break if same definition is already extracted
  if index(res, file) != -1
    return iced#promise#resolve(join(res, "\n"))
  endif

  call add(res, file)
  let delete_indent_level = get(definition, 'col-beg', 0) + len(get(definition, 'name', ''))
  let def_code = get(definition, 'definition', '')
  let match_code = get(definition, 'match', '')
  " Use the one with more information
  let code = (len(def_code) >= len(match_code)) ? def_code : match_code
  let code = iced#util#del_indent(delete_indent_level, code)
  call add(res, code)

  " Extract backward when the same symbol exists in the matched string
  let idx = stridx(match_code, definition['name'], 1)
  if idx == -1 || a:level >= g:iced#nrepl#source#finding_max_depth - 1
    return iced#promise#resolve(join(res, "\n"))
  else
    let opt = copy(definition)
    let opt['col-beg'] = get(definition, 'col-beg', 0) + idx
    let opt['result'] = copy(res)
    let opt['level'] = a:level + 1
    return s:__fetch_definition(opt)
  endif
endfunction

function! s:__fetch_definition(...) abort
  let opt = get(a:, 1, {})
  let pos = getcurpos()
  let ns_name = iced#nrepl#ns#name()

  let path = get(opt, 'file', expand('%:p'))
  let sym = get(opt, 'name', iced#nrepl#var#cword())
  let line = get(opt, 'line-beg', pos[1])
  let column = get(opt, 'col-beg', pos[2])
  let result = get(opt, 'result', [])
  let level = get(opt, 'level', 0)

  return iced#promise#call('iced#nrepl#op#refactor#extract_definition', [path, ns_name, sym, line, column])
       \.then({resp -> (type(resp) == v:t_dict && has_key(resp, 'definition'))
       \               ? iced#promise#call(iced#system#get('edn').decode, [resp['definition']])
       \               : (level > 0) ? '' : s:__fetch_source(sym)
       \               })
       \.then(funcref('s:__format_definition_codes', [level, result]))
endfunction
" }}}

function! iced#nrepl#source#show(symbol) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let cword = iced#nrepl#var#cword()
  let symbol = empty(a:symbol) ? cword : a:symbol

  return ((symbol ==# cword && g:iced_enable_enhanced_definition_extraction && iced#system#get('edn').is_available())
        \ ? s:__fetch_definition()
        \ : s:__fetch_source(symbol))
        \.then({code -> empty(code)
        \               ? iced#promise#reject(iced#message#get('not_found'))
        \               : iced#buffer#document#open(code, 'clojure')})
        \.catch({err -> iced#message#error_str(err)})
endfunction

function! s:try_to_fallback(symbol, err) abort
  let err_type = type(a:err)
  if err_type == v:t_string
    return iced#message#error_str(a:err)
  elseif err_type != v:t_dict
        \ || !has_key(a:err, 'exception')
    return iced#message#error('unexpected_error', string(a:err))
  endif

  let ex = a:err['exception']
  if stridx(ex, 'vim-iced: too long texts to show in popup') == 0
    call iced#nrepl#source#show(a:symbol)
  endif

  return iced#message#warning('popup_error', string(ex))
endfunction

function! iced#nrepl#source#popup_show(symbol) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  if !iced#system#get('popup').is_supported()
    return iced#nrepl#source#show(a:symbol)
  endif

  let cword = iced#nrepl#var#cword()
  let symbol = empty(a:symbol) ? cword : a:symbol

  return ((symbol ==# cword && g:iced_enable_enhanced_definition_extraction && iced#system#get('edn').is_available())
        \ ? s:__fetch_definition()
        \ : s:__fetch_source(symbol))
        \.then({code -> empty(code)
        \               ? iced#message#error('not_found')
        \               : iced#system#get('popup').open(
        \                   split(code, '\r\?\n'), {
        \                   'group': '_document_',
        \                   'line': 'near-cursor',
        \                   'col': 'near-cursor',
        \                   'filetype': 'clojure',
        \                   'border': [],
        \                   'borderhighlight': ['Comment'],
        \                   'auto_close': v:false,
        \                   'moved': 'any',
        \                   })})
        \.catch({err -> s:try_to_fallback(a:symbol, err)})
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
