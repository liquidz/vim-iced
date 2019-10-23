let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {
      \ 'opening': v:false,
      \ 'last_texts': [],
      \ 'last_opts': {},
      \ }

function! s:helper.is_supported() abort
  return v:true
endfunction

function! s:helper.get_context(winid) abort
  return get(self.last_opts, 'iced_context', {})
endfunction

function! s:helper.open(texts, ...) abort
  let self.opening = v:true
  let self.last_texts = copy(a:texts)
  let self.last_opts = copy(get(a:, 1, {}))
  return 123
endfunction

function! s:helper.close(winid) abort
  let self.opening = v:false
  return v:true
endfunction

function! s:helper.is_opening() abort
  return self.opening
endfunction

function! s:helper.get_last_texts() abort
  return self.last_texts
endfunction

function! s:helper.get_last_opts() abort
  return self.last_opts
endfunction

function! s:helper.mock() abort
  call iced#system#set_component('popup', {'constructor': {_ -> self}})
endfunction

function! themis#helper#iced_popup#new(runner) abort
  return deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
