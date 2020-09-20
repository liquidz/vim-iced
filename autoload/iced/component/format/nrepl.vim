let s:save_cpo = &cpoptions
set cpoptions&vim

let g:iced#format#does_overwrite_rules = get(g:, 'iced#format#does_overwrite_rules', v:false)
let g:iced#format#rule = get(g:, 'iced#format#rule', {})

let s:fmt = {
      \ 'sign': '',
      \ }

function! s:set_indentation_rule() abort
  call iced#cache#do_once('set-indentation-rule', {->
        \ iced#util#has_status(
        \   iced#nrepl#op#iced#sync#set_indentation_rules(
        \     g:iced#format#rule,
        \     g:iced#format#does_overwrite_rules),
        \   'done')})
endfunction

function! s:__format_finally(self, args) abort
  let current_bufnr = get(a:args, 'back_to_bufnr', bufnr('%'))
  let different_buffer = (current_bufnr != a:args.context.bufnr)
  if different_buffer | call iced#buffer#focus(a:args.context.bufnr) | endif

  setl modifiable
  call iced#util#restore_context(a:args.context)
  call a:self.sign.refresh({'signs': a:args.signs})

  if different_buffer | call iced#buffer#focus(current_bufnr) | endif
endfunction

" format all {{{
function! s:__append_texts(lnum, texts) abort
  let lnum = a:lnum
  for txt in a:texts
    call append(lnum, txt)
    let lnum += 1
  endfor
  normal! dd
endfunction

function! s:__format_all(resp, finally_args) abort
  let current_bufnr = bufnr('%')
  if current_bufnr != a:finally_args.context.bufnr
    call iced#buffer#focus(a:finally_args.context.bufnr)
  endif
  setl modifiable

  if has_key(a:resp, 'formatted') && !empty(a:resp['formatted'])
    silent! execute "normal! i \<esc>x"
          \ | undojoin
          \ | %del
          \ | call s:__append_texts(0, split(a:resp['formatted'], '\r\?\n'))
  elseif has_key(a:resp, 'error')
    call iced#message#error_str(a:resp['error'])
  endif

  let finally_args = copy(a:finally_args)
  let finally_args['back_to_bufnr'] = current_bufnr
  return finally_args
endfunction

function! s:fmt.all() abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let context = iced#util#save_context()
  let codes = trim(join(getline(1, '$'), "\n"))
  if empty(codes) | return | endif

  call s:set_indentation_rule()

  let ns_name = iced#nrepl#ns#name()
  let alias_dict = iced#nrepl#ns#alias_dict(ns_name)
  let finally_args = {
        \ 'context': context,
        \ 'signs': copy(self.sign.list_in_buffer()),
        \ }

  " Disable editing until the formatting process is completed
  setl nomodifiable
  return iced#promise#new({resolve ->
        \   iced#nrepl#op#iced#format_code(codes, alias_dict, {resp ->
        \     resolve(s:__format_finally(self, s:__format_all(resp, finally_args)))
        \   })
        \ })
endfunction " }}}

" format current form {{{
function! s:__format_form(resp, finally_args) abort
  let current_bufnr = bufnr('%')
  if current_bufnr != a:finally_args.context.bufnr
    call iced#buffer#focus(a:finally_args.context.bufnr)
  endif
  setl modifiable

  if has_key(a:resp, 'formatted') && !empty(a:resp['formatted'])
    let @@ = a:resp['formatted']
    silent normal! gvp
  elseif has_key(a:resp, 'error')
    call iced#message#error_str(a:resp['error'])
  endif

  let finally_args = copy(a:finally_args)
  let finally_args['back_to_bufnr'] = current_bufnr
  return finally_args
endfunction

function! s:fmt.current_form() abort
  if !iced#nrepl#is_connected()
    silent exe "normal \<Plug>(sexp_indent)"
    return
  endif

  " must be captured before get_current_top_something
  let context = iced#util#save_context()

  let codes = get(iced#paredit#get_current_top_something(), 'code', '')
  if empty(codes) | return iced#message#warning('finding_code_error') | endif

  call winrestview(context.view)
  call s:set_indentation_rule()

  let ns_name = iced#nrepl#ns#name()
  let alias_dict = iced#nrepl#ns#alias_dict(ns_name)
  let finally_args = {
        \ 'context': context,
        \ 'signs': copy(self.sign.list_in_buffer()),
        \ }

  " Disable editing until the formatting process is completed
  setl nomodifiable
  return iced#promise#new({resolve ->
        \   iced#nrepl#op#iced#format_code(codes, alias_dict, {resp ->
        \     resolve(s:__format_finally(self, s:__format_form(resp, finally_args)))
        \   })
        \ })
endfunction " }}}

" format minimal {{{
function! s:fmt.minimal(opt) abort
  if !iced#nrepl#is_connected()
    silent exe "normal \<Plug>(sexp_indent)"
    return
  endif

  let jump_to_its_match = get(a:opt, 'jump_to_its_match', v:true)

  call s:set_indentation_rule()

  let view = winsaveview()
  let reg_save = @@
  let ns_name = iced#nrepl#ns#name()
  try
    if jump_to_its_match
      " NOTE: vim-sexp's slurp move cursor to tail of form
      normal! %
    endif

    let ncol = max([col('.')-1, 0])

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
endfunction " }}}

" calculate indent level {{{
function! s:fmt.calculate_indent(lnum) abort
  if !iced#nrepl#is_connected()
    return GetClojureIndent()
  endif

  call s:set_indentation_rule()

  let view = winsaveview()
  let reg_save = @@
  let ns_name = iced#nrepl#ns#name()
  try
    let res = iced#paredit#get_current_top_something()
    let code = get(res, 'code', '')
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
endfunction " }}}

function! iced#component#format#nrepl#start(this) abort
  call iced#util#debug('start', 'format nrepl')
  let d = deepcopy(s:fmt)
  let d.sign = a:this.sign
  return d
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
