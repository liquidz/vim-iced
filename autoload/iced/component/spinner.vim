let s:save_cpo = &cpoptions
set cpoptions&vim

let s:spinner = {
      \ 'timer': '',
      \ 'virtual_text': '',
      \ 'working_spinners': {},
      \ }

function! s:start_spinner__spinner(uniq_key, opt) abort dict
  let buffer = get(a:opt, 'buffer', bufnr('%'))
  let line = get(a:opt, 'line', line('.'))
  let idx = get(a:opt, 'index', 0)
  let texts = get(a:opt, 'texts', [' |', ' /', '-', ' \'])
  let highlight = get(a:opt, 'highlight', 'Comment')
  let align = get(a:opt, 'align', 'after')
  let interval = get(a:opt, 'interval', 200)

  let idx = idx >= len(texts) ? 0 : idx

  if has_key(self.working_spinners, a:uniq_key)
    call self.virtual_text.set(texts[idx], {
          \ 'highlight': highlight,
          \ 'align': align,
          \ 'buffer': buffer,
          \ 'line': line,
          \ 'auto_clear': v:false,
          \ 'indent': 0,
          \ })

    let new_opt = copy(a:opt)
    let new_opt['index'] = idx + 1
    let new_opt['buffer'] = buffer
    let new_opt['line'] = line
    return self.timer.start(
          \ interval,
          \ {-> call(funcref('s:start_spinner__spinner'), [a:uniq_key, new_opt], self)})
  endif
endfunction

function! s:spinner.start(uniq_key, opt) abort
  " NOTE: Spinner is only supported by Vim9/Neovim
  if self.virtual_text.env ==# 'vim8'
    return
  endif

  let self.working_spinners[a:uniq_key] = v:true
  return self.timer.start(200, {-> call(funcref('s:start_spinner__spinner'), [a:uniq_key, a:opt], self)})
endfunction

function! s:spinner.stop(uniq_key) abort
  if has_key(self.working_spinners, a:uniq_key)
    unlet self.working_spinners[a:uniq_key]
  endif
endfunction

function! iced#component#spinner#start(this) abort
  call iced#util#debug('start', 'spinner')
  let d = deepcopy(s:spinner)
  let d['timer'] = a:this.timer
  let d['virtual_text'] = a:this.virtual_text
  return d
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
