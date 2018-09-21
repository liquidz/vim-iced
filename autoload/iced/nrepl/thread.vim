let s:save_cpo = &cpo
set cpo&vim

function! s:threading(fn) abort
  let view = winsaveview()
  let reg_save = @@

  try
    let code = iced#paredit#get_outer_list_raw()
    if !empty(code)
      let resp = a:fn(code)
      if has_key(resp, 'error')
        call iced#message#error_str(resp['error'])
      elseif has_key(resp, 'code')
        let @@ = resp['code']
        silent normal! gvp
      endif
    endif
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

function! iced#nrepl#thread#first() abort
  call s:threading({code -> iced#nrepl#iced#sync#refactor_thread_first(code)})
endfunction

function! iced#nrepl#thread#last() abort
  call s:threading({code -> iced#nrepl#iced#sync#refactor_thread_last(code)})
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
