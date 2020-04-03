let s:save_cpo = &cpo
set cpo&vim

let g:iced#eval#inside_comment = get(g:, 'iced#eval#inside_comment', v:true)
let g:iced#eval#mark_at_last = get(g:, 'iced#eval#mark_at_last', '1')

let s:repl = {}

function! iced#repl#status() abort
  if empty(s:repl) | return 'not connected' | endif
  return s:repl.status()
endfunction

function! iced#repl#is_connected() abort
  if empty(s:repl) | return v:false | endif
  return s:repl.is_connected()
endfunction

function! iced#repl#connect(target, ...) abort
  let s:repl = iced#system#get(a:target)
  if empty(s:repl)
    return iced#message#error('connect_error')
  endif

  let result = call(s:repl.connect, a:000)
  if !result
    let s:repl = {}
  endif

  return s:repl
endfunction

" c.f. :h :command-completion-custom
function! iced#repl#instant_connect_complete(arg_lead, cmd_line, cursor_pos) abort
  let res = ['nrepl']
  call extend(res, iced#socket_repl#connect#supported_programs())
  return join(res, "\n")
endfunction

function! iced#repl#instant_connect(target) abort
  if a:target ==# '' || a:target ==# 'nrepl'
    call iced#nrepl#connect#instant()
  elseif a:target ==# 'prepl'
    call iced#prepl#connect#instant()
  else
    call iced#socket_repl#connect#instant(a:target)
  endif
endfunction

function! iced#repl#get(feature_name) abort
  return get(s:repl, a:feature_name)
endfunction

function! iced#repl#execute(feature_name, ...) abort
  let Fn = get(s:repl, a:feature_name)
  if type(Fn) == v:t_func
    return call(Fn, a:000)
  endif
endfunction

function! iced#repl#eval_at_mark(mark) abort
  if getpos(printf("'%s", a:mark)) == [0, 0, 0, 0]
    return
  endif

  let context = iced#util#save_context()
  " To show virtual text at current line
  let opt = {'virtual_text': {
        \ 'line': has('nvim') ? winline()-1 : winline(),
        \ 'col': col('$') + 3,
        \ 'buffer': bufnr('%'),
        \ }}

  try
    " Move cursor at mark
    silent execute printf("normal! `%s", a:mark)

    let p = iced#repl#execute('eval_outer_top_list', opt)
    if iced#promise#is_promise(p)
      call iced#promise#wait(p)
    endif
  finally
    call iced#util#restore_context(context)
  endtry
endfunction

function! iced#repl#eval_last_outer_top_list() abort
  return iced#repl#eval_at_mark(g:iced#eval#mark_at_last)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
