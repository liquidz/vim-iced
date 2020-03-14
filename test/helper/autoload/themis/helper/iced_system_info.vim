let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {
      \ 'dummies': {
      \   'user-dir': '/path/to/user/dir',
      \   'file-separator': '/',
      \   'project-name': 'vim-iced-test',
      \   'piggieback-enabled?': v:false,
      \   }
      \ }

function! s:helper.set_dummies() abort
  call iced#cache#merge(copy(self.dummies))
endfunction

function! s:helper.get_dummy_user_dir() abort
  return self.dummies['user-dir']
endfunction

function! s:helper.clear_dummies() abort
  for kw in keys(self.dummies)
    call iced#cache#delete(kw)
  endfor
endfunction

function! themis#helper#iced_system_info#new(runner) abort
  return deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
