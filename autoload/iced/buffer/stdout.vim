scriptencoding utf-8
let s:save_cpo = &cpoptions
set cpoptions&vim

let s:bufname = 'iced_stdout'
let s:default_init_text = join([
    \ ';;',
    \ ';; Iced Buffer',
    \ ';;',
    \ '',
    \ ], "\n")

let g:iced#buffer#stdout#init_text = get(g:, 'iced#buffer#stdout#init_text', s:default_init_text)
let g:iced#buffer#stdout#mods = get(g:, 'iced#buffer#stdout#mods', '')
let g:iced#buffer#stdout#max_line = get(g:, 'iced#buffer#stdout#max_line', -1)
let g:iced#buffer#stdout#deleting_line_delay = get(g:, 'iced#buffer#stdout#deleting_line_delay', 1000)
let g:iced#buffer#stdout#file = get(g:, 'iced#buffer#stdout#file', '')
let g:iced#buffer#stdout#file_buffer_size = get(g:, 'iced#buffer#stdout#file_buffer_size', 256)
let g:iced#buffer#stdout#enable_notify = get(g:, 'iced#buffer#stdout#enable_notify', v:true)

function! s:delete_old_lines(_) abort
  let bufnr = iced#buffer#nr(s:bufname)
  let buflen = len(getbufline(bufnr, 0, '$'))
  if g:iced#buffer#stdout#max_line > 0 && buflen > g:iced#buffer#stdout#max_line
    let line_diff = buflen - g:iced#buffer#stdout#max_line
    call iced#compat#deletebufline(bufnr, 1, line_diff)

    if iced#buffer#stdout#is_visible()
      let current_window = winnr()
      try
        call iced#buffer#stdout#focus()
        let view = winsaveview()
        let view['topline'] = max([1, view['topline'] - line_diff])
        call winrestview(view)
      finally
        execute current_window . 'wincmd w'
      endtry
    endif
  endif
endfunction

function! s:initialize(bufnr) abort
  call setbufvar(a:bufnr, '&bufhidden', 'hide')
  call setbufvar(a:bufnr, '&buflisted', 0)
  call setbufvar(a:bufnr, '&buftype', 'nofile')
  call setbufvar(a:bufnr, '&filetype', 'clojure')
  call setbufvar(a:bufnr, '&swapfile', 0)
  call setbufvar(a:bufnr, '&wrap', 0)

  for line in split(g:iced#buffer#stdout#init_text, '\r\?\n')
    silent call iced#compat#appendbufline(a:bufnr, '$', line)
  endfor
  silent call iced#compat#deletebufline(a:bufnr, 1)

  if !empty(g:iced#buffer#stdout#file)
    call writefile(getbufline(a:bufnr, 1, '$'), g:iced#buffer#stdout#file)
  endif
endfunction

function! iced#buffer#stdout#init() abort
  return iced#buffer#init(s:bufname, funcref('s:initialize'))
endfunction

function! iced#buffer#stdout#open() abort
  call iced#buffer#open(
      \ s:bufname,
      \ {'mods': g:iced#buffer#stdout#mods,
      \  'scroll_to_bottom': v:true})
endfunction

let s:write_file_buffer = []
function! s:flush_writing_file(_) abort
  let tmp = copy(s:write_file_buffer)
  let s:write_file_buffer = []
  call writefile(tmp, g:iced#buffer#stdout#file, 'a')
endfunction

function! iced#buffer#stdout#append(s) abort
  let s = iced#util#delete_color_code(a:s)
  let timer = iced#system#get('timer')

  if !empty(g:iced#buffer#stdout#file)
    call extend(s:write_file_buffer, split(s, '\r\?\n'))
    if len(s:write_file_buffer) > g:iced#buffer#stdout#file_buffer_size
      call writefile(copy(s:write_file_buffer), g:iced#buffer#stdout#file, 'a')
      call timer.start_lazily('flush_writing_file', 500, funcref('s:flush_writing_file'))
      let s:write_file_buffer = []
    endif
  endif

  call iced#buffer#append(
      \ s:bufname,
      \ s,
      \ {'scroll_to_bottom': v:true})

  call timer.start_lazily(
        \ 'delete_old_lines',
        \ g:iced#buffer#stdout#deleting_line_delay,
        \ funcref('s:delete_old_lines'),
        \ )

  if ! iced#buffer#stdout#is_visible()
        \ && g:iced#buffer#stdout#enable_notify
    silent call iced#system#get('notify').notify(s, {'title': 'Stdout'})
  endif
endfunction

function! iced#buffer#stdout#clear() abort
  call iced#buffer#clear(s:bufname, funcref('s:initialize'))
endfunction

function! iced#buffer#stdout#close() abort
  call iced#buffer#close(s:bufname)
endfunction

function! iced#buffer#stdout#is_visible() abort
  return iced#buffer#is_visible(s:bufname)
endfunction

function! iced#buffer#stdout#focus() abort
  call iced#buffer#focus(s:bufname)
endfunction

function! iced#buffer#stdout#toggle() abort
  if iced#buffer#stdout#is_visible()
    call iced#buffer#stdout#close()
  else
    call iced#buffer#stdout#open()
  endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
