scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:default_init_text = join([
    \ ';;',
    \ ';; Iced Buffer',
    \ ';;',
    \ '',
    \ ], "\n")

let g:iced#buffer#stdout#init_text = get(g:, 'iced#buffer#stdout#init_text', s:default_init_text)
let g:iced#buffer#stdout#mods = get(g:, 'iced#buffer#stdout#mods', '')
let g:iced#buffer#stdout#max_line = get(g:, 'iced#buffer#stdout#max_line', 512)
let g:iced#buffer#stdout#file = get(g:, 'iced#buffer#stdout#file', '')

function! s:delete_color_code(s) abort
  return substitute(a:s, '\[[0-9;]*m', '', 'g')
endfunction

function! s:initialize(bufnr) abort
  call setbufvar(a:bufnr, '&buflisted', 0)
  call setbufvar(a:bufnr, '&buftype', 'nofile')
  call setbufvar(a:bufnr, '&filetype', 'clojure')
  call setbufvar(a:bufnr, '&swapfile', 0)

  for line in split(g:iced#buffer#stdout#init_text, '\r\?\n')
    silent call iced#compat#appendbufline(a:bufnr, '$', line)
  endfor
  silent call iced#compat#deletebufline(a:bufnr, 1)

  if !empty(g:iced#buffer#stdout#file)
    call writefile(getbufline(a:bufnr, 1, '$'), g:iced#buffer#stdout#file)
  endif
endfunction

let s:stdout = {
      \ 'bufname': 'iced_stdout',
      \ 'state': {'buffer': {}},
      \ }

function! s:stdout.open() abort
  call self.state.buffer.open(
        \ self.bufname,
        \ {'mods': g:iced#buffer#stdout#mods,
        \  'scroll_to_bottom': v:true})
endfunction

function! s:stdout.append(s) abort
  let s = s:delete_color_code(a:s)
  if !empty(g:iced#buffer#stdout#file)
    call writefile(split(s, '\r\?\n'), g:iced#buffer#stdout#file, 'a')
  endif

  call self.state.buffer.append(
      \ self.bufname,
      \ s,
      \ {'scroll_to_bottom': v:true})
endfunction

function! s:stdout.clear() abort
  call self.state.buffer.clear(self.bufname, funcref('s:initialize'))
endfunction

function! s:stdout.close() abort
  call self.state.buffer.close(self.bufname)
endfunction

function! s:stdout.is_visible() abort
  return self.state.buffer.is_visible(self.bufname)
endfunction

function! iced#state#buffer#stdout#start(params) abort
  let this = deepcopy(s:stdout)
  let this['state']['buffer'] = a:params.require.buffer

  call this.state.buffer.init(this.bufname, funcref('s:initialize'))

  return this
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
