let s:save_cpo = &cpo
set cpo&vim

let s:V  = vital#iced#new()
let s:B  = s:V.import('Vim.Buffer')
let s:BM = s:V.import('Vim.BufferManager')

" utilities {{{
function! s:focus_window(bufwin_num) abort
  execute a:bufwin_num . 'wincmd w'
endfunction

function! s:apply_option(opt) abort
  if get(a:opt, 'scroll_to_top', v:false)
    silent normal! gg
  elseif get(a:opt, 'scroll_to_bottom', v:false)
    silent normal! G
  endif
endfunction
" }}}

let s:buffer = {
      \ 'namager': '',
      \ 'state': {'ex_cmd': {}},
      \ 'info': {}}

function! s:buffer.bufwinnr(bufname) abort
  return bufwinnr(self.bufnr(a:bufname))
endfunction

function! s:buffer.bufnr(bufname) abort
  let info = get(self.info, a:bufname, {})
  return get(info, 'bufnr', -1)
endfunction

function! s:buffer.nr(bufname) abort
  let info = get(self.info, a:bufname, {})
  return get(info, 'bufnr', -1)
endfunction

function! s:buffer.init(bufname, ...) abort
  let self.info[a:bufname] = self.manager.open(a:bufname)

  let InitFn = get(a:, 1, '')
  if type(InitFn) == v:t_func
    call InitFn(self.bufnr(a:bufname))
  endif

  call self.state.ex_cmd.silent_exe(':q')
endfunction

function! s:buffer.is_visible(bufname) abort
  return (self.bufwinnr(a:bufname) != -1)
endfunction

function! s:buffer.set_var(bufname, k, v) abort
  let nr = self.bufnr(a:bufname)
  if nr < 0 | return | endif
  silent call setbufvar(nr, a:k, a:v)
endfunction

function! s:buffer.open(bufname, ...) abort
  let nr = self.bufnr(a:bufname)
  if nr < 0 | return | endif
  let current_window = winnr()
  let opt = get(a:, 1, {})

  if self.is_visible(a:bufname)
    call s:focus_window(self.bufwinnr(a:bufname))
    call s:apply_option(opt)
  else
    call s:B.open(nr, {
        \ 'opener': get(opt, 'opener', 'split'),
        \ 'mods': get(opt, 'mods', ''),
        \ })

    if has_key(opt, 'height')
      silent exec printf(':resize %d', opt['height'])
    endif

    call s:apply_option(opt)
    call s:focus_window(current_window)
  endif
endfunction

function! s:buffer.append(bufname, s, ...) abort
  let nr = self.bufnr(a:bufname)
  if nr < 0 | return | endif
  let opt = get(a:, 1, {})

  for line in split(a:s, '\r\?\n')
    silent call iced#compat#appendbufline(nr, '$', line)
  endfor

  call iced#nrepl#auto#enable_winenter(v:false)
  try
    if get(opt, 'scroll_to_bottom', v:false) && self.is_visible(a:bufname)
      let current_window = winnr()
      call s:focus_window(bufwinnr(nr))
      silent normal! G
      call s:focus_window(current_window)
    endif
  finally
    call iced#nrepl#auto#enable_winenter(v:true)
  endtry
endfunction

function! s:buffer.set_contents(bufname, s) abort
  let nr = self.bufnr(a:bufname)

  silent call iced#compat#deletebufline(nr, 1, '$')
  for line in split(a:s, '\r\?\n')
    silent call iced#compat#appendbufline(nr, '$', line)
  endfor
  silent call iced#compat#deletebufline(nr, 1)
endfunction

function! s:buffer.clear(bufname, ...) abort
  let nr = self.bufnr(a:bufname)
  silent call iced#compat#deletebufline(nr, 1, '$')
  let InitFn = get(a:, 1, '')
  if type(InitFn) == v:t_func
    call InitFn(nr)
  endif
endfunction

function! s:buffer.close(bufname) abort
  if !self.is_visible(a:bufname)
    return
  endif

  let current_window = winnr()
  let target_window = self.bufwinnr(a:bufname)
  call s:focus_window(target_window)
  call self.state.ex_cmd.silent_exe(':q')

  if target_window >= current_window
    call s:focus_window(current_window)
  endif
endfunction

function! iced#state#buffer#start(params) abort
  let b = deepcopy(s:buffer)
  let b['manager'] = s:BM.new()
  let b['state']['ex_cmd'] = a:params['require']['ex_cmd']
  return b
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
