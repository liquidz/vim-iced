let s:save_cpo = &cpoptions
set cpoptions&vim

let s:vt = {
      \ 'timer': '',
      \ 'textprop_type': 'iced_virtual_text',
      \ }

function! s:vt.set(text, ...) abort
  let opt = get(a:, 1, {})
  let line = get(opt, 'line', line('.'))
  let align = get(opt, 'align', 'after')

  if prop_type_get(self.textprop_type) == {}
    call prop_type_add(self.textprop_type, {'highlight': get(opt, 'highlight', 'Comment')})
  endif

  call prop_add(line, 0, {
        \ 'type': self.textprop_type,
        \ 'text': printf(' %s', a:text),
        \ 'text_align': align,
        \ })

  if get(opt, 'auto_clear', v:false)
    let time = get(opt, 'clear_time', 3000)
    call self.timer.start(time, {-> prop_clear(line)})
  endif
endfunction

function! s:vt.clear(...) abort
  let opt = get(a:, 1, {})
  let buf = get(opt, 'buffer', bufnr('%'))

  if empty(opt)
    call prop_clear(1, line('$'))
  else
    let line = get(opt, 'line', line('.') -1)
    call prop_clear(line, line('$'))
  endif
endfunction

function! iced#component#virtual_text#vim9#start(this) abort
  call iced#util#debug('start', 'vim9 virtual_text')
  let d = deepcopy(s:vt)
  let d['timer'] = a:this.timer
  return d
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
