let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {
      \ 'signs': [],
      \ 'default_group': 'test_group',
      \ }

function! s:helper.place(name, lnum, file, ...) abort
  let group = get(a:, 1, self.default_group)
  let id = len(self.signs)
  call add(self.signs, {
        \ 'name': a:name,
        \ 'lnum': a:lnum,
        \ 'file': a:file,
        \ 'group': group,
        \ })
  return id
endfunction

function! s:helper.list_in_buffer(...) abort
  let file = get(a:, 1, expand('%:p'))
  return filter(copy(self.signs), {_, v -> v['file'] ==# file})
endfunction

function! s:helper.all_list(...) abort
  return copy(self.signs)
endfunction

function! s:helper.jump_to_next(...) abort
  return
endfunction

function! s:helper.jump_to_prev(...) abort
  return
endfunction

function! s:helper.unplace_by(opt) abort
  let self.signs = []
  return
endfunction

function! s:helper.refresh(...) abort
endfunction

function! s:helper.mock() abort
  call iced#system#set_component('sign', {'start': {_ -> self}})
endfunction

function! s:helper.clear() abort
  let self.signs = []
  return
endfunction

function! themis#helper#iced_sign#new(runner) abort
  return deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
