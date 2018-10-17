let s:save_cpo = &cpo
set cpo&vim

let s:is_indentation_rule_setted = v:false
" NOTE: used in iced/nrepl/format.vim
let g:iced#format#rule = get(g:, 'iced#format#rule', {})

function! s:set_indentation_rule() abort
  if s:is_indentation_rule_setted
    return
  endif

  let resp = iced#nrepl#op#iced#sync#set_indentation_rules(g:iced#format#rule)
  if iced#util#has_status(resp, 'done')
    let s:is_indentation_rule_setted = v:true
  endif
endfunction

function! s:ns_aliases(ns_code) abort
  try
    let resp = iced#nrepl#op#iced#sync#ns_aliases(a:ns_code)
    return get(resp, 'aliases', {})
  catch
    return {}
  endtry
endfunction

function! iced#format#form() abort
  if !iced#nrepl#is_connected()
    silent exe "normal \<Plug>(sexp_indent)"
    return
  endif

  if ! s:is_indentation_rule_setted
    call s:set_indentation_rule()
  endif

  let view = winsaveview()
  let reg_save = @@
  let ns_code = iced#nrepl#ns#get()
  try
    let res = iced#paredit#get_current_top_list_raw()
    let code = res['code']
    if empty(code)
      call iced#message#warning('finding_code_error')
    else
      let resp = iced#nrepl#op#iced#sync#format_code(code, s:ns_aliases(ns_code))
      if has_key(resp, 'formatted') && !empty(resp['formatted'])
        let @@ = join(split(resp['formatted'], '[\r\n]\+'), "\n")
        silent normal! gvp
      elseif has_key(resp, 'error')
        call iced#message#error_str(resp['error'])
      endif
    endif
  finally
    let @@ = reg_save
    call winrestview(view)
    call iced#sign#refresh()
  endtry
endfunction

function! iced#format#minimal() abort
  if !iced#nrepl#is_connected()
    silent exe "normal \<Plug>(sexp_indent)"
    return
  endif

  if ! s:is_indentation_rule_setted
    call s:set_indentation_rule()
  endif

  let view = winsaveview()
  let reg_save = @@
  let ns_code = iced#nrepl#ns#get()
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
    let resp = iced#nrepl#op#iced#sync#format_code(code, s:ns_aliases(ns_code))
    if has_key(resp, 'formatted') && !empty(resp['formatted'])
      let formatted = join(split(resp['formatted'], '[\r\n]\+'), "\n")
      let @@ = iced#util#add_indent(ncol, formatted)
      silent normal! gvp
    endif
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
