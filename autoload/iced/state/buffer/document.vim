let s:save_cpo = &cpo
set cpo&vim

let s:document = {
      \ 'bufname': 'iced_document',
      \ 'state': {'buffer': {}},
      \ }

let s:default_filetype = 'markdown'

let g:iced#buffer#document#height = get(g:, 'iced#buffer#document#height', &previewheight)

function! s:initialize(bufnr) abort
  call setbufvar(a:bufnr, '&buflisted', 0)
  call setbufvar(a:bufnr, '&buftype', 'nofile')
  call setbufvar(a:bufnr, '&filetype', s:default_filetype)
  call setbufvar(a:bufnr, '&swapfile', 0)
endfunction

function! s:document.is_visible() abort
  return self.state.buffer.is_visible(self.bufname)
endfunction

function! s:document.open(text, ...) abort
  let ft = get(a:, 1, s:default_filetype)
  call self.state.buffer.set_var(self.bufname, '&filetype', ft)
  call self.state.buffer.set_contents(self.bufname, a:text)
  call self.state.buffer.open(
      \ self.bufname,
      \ {'opener': 'split',
      \  'mods': 'belowright',
      \  'scroll_to_top': v:true,
      \  'height': g:iced#buffer#document#height,
      \ })
endfunction

function! s:document.update(text, ...) abort
  let ft = get(a:, 1, s:default_filetype)
  call self.state.buffer.set_var(self.bufname, '&filetype', ft)
  call self.state.buffer.set_contents(self.bufname, a:text)
endfunction

function! s:document.close() abort
  call self.state.buffer.close(self.bufname)
endfunction

function! iced#state#buffer#document#start(params) abort
  let this = deepcopy(s:document)
  let this['state']['buffer'] = a:params.require.buffer

  call this.state.buffer.init(this.bufname, funcref('s:initialize'))

  return this
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
