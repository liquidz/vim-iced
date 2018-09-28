let s:save_cpo = &cpo
set cpo&vim

function! iced#let#goto() abort
  let view = winsaveview()
  let reg_save = @@

  try
    call iced#paredit#move_to_prev_top_element()
    let stopline = line('.')
    call winrestview(view)
    let ret = search('(let[ \r\n]', 'b', stopline)
    if ret != 0
      call search('\[')
    endif
    return ret
  finally
    let @@ = reg_save
  endtry
endfunction

function! iced#let#move_to_let() abort
  let view = winsaveview()
  let reg_save = @@

  try
    let form = iced#paredit#get_outer_list_raw()
    if empty(form) | return iced#message#error('not_found') | endif

    let indent = col('.')-1
    let form = iced#util#del_indent(indent, form)
    let name = trim(input('Name: '))

    if iced#let#goto() == 0
      " 6 means `len('(let [')`
      let form = iced#util#add_indent(len(name)+1+6, form)
      let @@ = iced#util#add_indent(
            \ indent, printf("(let [%s %s]\n  %s)", name, form, name))
      silent normal! gvp
    else
      let pos = getcurpos()
      let @@ = name
      silent normal! gvp
      call setpos('.', pos)

      silent normal! vi[y
      let bindings = @@
      let indent = col('.')-1

      let form = iced#util#add_indent(len(name)+1, form)
      let @@ = iced#util#add_indent(
            \ indent, printf("%s\n%s %s", bindings, name, form))
      silent normal! gvp
    endif

    let view['lnum'] = view['lnum'] + len(split(form, '\r\?\n'))
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
