let s:save_cpo = &cpo
set cpo&vim

let s:error = {
      \ 'bufname': 'iced_error',
      \ 'state': {'buffer': {}},
      \ }

let g:iced#buffer#error#height = get(g:, 'iced#buffer#error#height', &previewheight)

function! s:initialize(bufnr) abort
  call setbufvar(a:bufnr, '&buflisted', 0)
  call setbufvar(a:bufnr, '&buftype', 'nofile')
  call setbufvar(a:bufnr, '&filetype', 'clojure')
  call setbufvar(a:bufnr, '&swapfile', 0)
endfunction

function! s:error.open() abort
  call self.state.buffer.open(
      \ self.bufname,
      \ {'opener': 'split',
      \  'mods': 'belowright',
      \  'scroll_to_top': v:true,
      \  'height': g:iced#buffer#error#height})
endfunction

function! s:error.show(text) abort
  if empty(a:text)
    call self.state.buffer.close(self.bufname)
    return
  endif

  call self.state.buffer.set_contents(self.bufname, a:text)
  call self.open()
endfunction


function! iced#state#buffer#error#start(params) abort
  let this = deepcopy(s:error)
  let this['state']['buffer'] = a:params.require.buffer

  call this.state.buffer.init(this.bufname, funcref('s:initialize'))

  return this
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
