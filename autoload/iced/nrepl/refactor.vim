let s:save_cpo = &cpo
set cpo&vim

function! iced#nrepl#refactor#extract_function() abort
  let private = {}
  
  function! private.used_locals(resp) abort
    if !has_key(a:resp, 'used-locals') | return iced#message#error('used_locals_error') | endif

    let view = winsaveview()
    let reg_save = @@

    try
      let locals = a:resp['used-locals']
      let func_name = trim(input('Function name: '))
      let func_body = iced#paredit#get_outer_list_raw()

      let @@ = printf('(%s %s)', func_name, join(locals, ' '))
      silent normal! gvp

      let code = printf("(defn- %s [%s]\n  %s)\n\n",
            \ func_name, join(locals, ' '),
            \ iced#util#add_indent(2, func_body))
      let codes = split(code, '\r\?\n')

      call iced#paredit#move_to_prev_top_element()
      call append(line('.')-1, codes)
      let view['lnum'] = view['lnum'] + len(codes)
    finally
      let @@ = reg_save
      call winrestview(view)
    endtry
  endfunction

  let path = expand('%:p')
  let pos = getcurpos()
  call iced#nrepl#op#refactor#find_used_locals(
        \ path, pos[1], pos[2], private.used_locals)
endfunction

let s:save_cpo = &cpo
set cpo&vim
