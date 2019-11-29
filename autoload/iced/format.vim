let s:save_cpo = &cpo
set cpo&vim

let g:iced#format#does_overwrite_rules = get(g:, 'iced#format#does_overwrite_rules', v:false)
let g:iced#format#rule = get(g:, 'iced#format#rule', {})

function! s:set_indentation_rule() abort
  call iced#cache#do_once('set-indentation-rule', {->
        \ iced#util#has_status(
        \   iced#nrepl#op#iced#sync#set_indentation_rules(
        \     g:iced#format#rule,
        \     g:iced#format#does_overwrite_rules),
        \   'done')})
endfunction

function! iced#format#all() abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call s:set_indentation_rule()

  let view = winsaveview()
  let reg_save = @@
  let ns_name = iced#nrepl#ns#name()
  let sign = iced#system#get('sign')
  let before_signs = copy(sign.list_in_buffer())

  try
    let codes = trim(join(getline(1, '$'), "\n"))
    if empty(codes) | return | endif

    let resp = iced#nrepl#op#iced#sync#format_code(codes, iced#nrepl#ns#alias_dict(ns_name))
    if has_key(resp, 'formatted') && !empty(resp['formatted'])
      %del
      call setline(1, split(resp['formatted'], '\r\?\n'))
    elseif has_key(resp, 'error')
      call iced#message#error_str(resp['error'])
    endif
  finally
    let @@ = reg_save
    call winrestview(view)
    call sign.refresh({'signs': before_signs})
  endtry
endfunction

function! iced#format#form() abort
  if !iced#nrepl#is_connected()
    silent exe "normal \<Plug>(sexp_indent)"
    return
  endif

  call s:set_indentation_rule()

  let view = winsaveview()
  let reg_save = @@
  let ns_name = iced#nrepl#ns#name()
  let sign = iced#system#get('sign')
  let before_signs = copy(sign.list_in_buffer())

  try
    let res = iced#paredit#get_current_top_list_raw()
    let code = res['code']
    if empty(code)
      call iced#message#warning('finding_code_error')
    else
      let resp = iced#nrepl#op#iced#sync#format_code(code, iced#nrepl#ns#alias_dict(ns_name))
      if has_key(resp, 'formatted') && !empty(resp['formatted'])
        let @@ = resp['formatted']
        silent normal! gvp
      elseif has_key(resp, 'error')
        call iced#message#error_str(resp['error'])
      endif
    endif
  finally
    let @@ = reg_save
    call winrestview(view)
    call sign.refresh({'signs': before_signs})
  endtry
endfunction

function! iced#format#minimal() abort
  if !iced#nrepl#is_connected()
    silent exe "normal \<Plug>(sexp_indent)"
    return
  endif

  call s:set_indentation_rule()

  let view = winsaveview()
  let reg_save = @@
  let ns_name = iced#nrepl#ns#name()
  try
    " NOTE: vim-sexp's slurp move cursor to tail of form
    normal! %
    let ncol = max([col('.')-1, 1])

    let char = getline('.')[ncol]
    if char ==# '['
      silent normal! va[y
    elseif char ==# '{'
      silent normal! va{y
    else
      silent normal! va(y
    endif
    let code = @@
    let resp = iced#nrepl#op#iced#sync#format_code(code, iced#nrepl#ns#alias_dict(ns_name))
    if has_key(resp, 'formatted') && !empty(resp['formatted'])
      let @@ = iced#util#add_indent(ncol, resp['formatted'])
      silent normal! gvp
    endif
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

function! iced#format#calculate_indent(lnum) abort
  if !iced#nrepl#is_connected()
    return GetClojureIndent()
  endif

  call s:set_indentation_rule()

  let view = winsaveview()
  let reg_save = @@
  let ns_name = iced#nrepl#ns#name()
  try
    let res = iced#paredit#get_current_top_list()
    let code = res['code']
    if trim(code) ==# ''
      return GetClojureIndent()
    endif

    let start_line = res['curpos'][1]
    let start_column = res['curpos'][2] - 1
    let target_lnum = a:lnum - start_line

    let resp = iced#nrepl#op#iced#sync#calculate_indent_level(code, target_lnum, iced#nrepl#ns#alias_dict(ns_name))
    if has_key(resp, 'indent-level') && type(resp['indent-level']) == v:t_number && resp['indent-level'] != 0
      return resp['indent-level'] + start_column
    else
      return GetClojureIndent()
    endif
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

function! iced#format#set_indentexpr() abort
  if get(g:, 'iced_enable_auto_indent', v:true)
    setlocal indentexpr=GetIcedIndent()
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
