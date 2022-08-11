let s:save_cpo = &cpoptions
set cpoptions&vim

let s:vt = {
      \ 'popup': '',
      \ 'ex_cmd': '',
      \ 'last_winid': v:null,
      \ 'textprop_id': 0,
      \ 'winids': {},
      \ 'id_limit': 10000,
      \ }

" Text property
let s:textprop_type = 'iced_virtual_text'
call prop_type_delete(s:textprop_type, {})
call prop_type_add(s:textprop_type, {})

function! s:id_for_current_line() abort
  return printf('%s:%s', bufnr('%'), line('.'))
endfunction

function! s:vt.inc_textprop_id() abort
  if self.textprop_id > self.id_limit
    let self.textprop_id = 0
  endif
  let self.textprop_id += 1

  call prop_remove({
        \ 'type': s:textprop_type,
        \ 'id': self.textprop_id,
        \ 'both': v:true,
        \ })
endfunction

function! s:vt.set(text, ...) abort
  let opt = get(a:, 1, {})
  let wininfo = getwininfo(win_getid())[0]

  " col
  let col = get(opt, 'col', col('$') + 3)
  " line
  let line = get(opt, 'line', winline())
  " width
  let max_width = wininfo['width'] - col
  if max_width < 0
    let col = wincol()
    let max_width = wininfo['width'] - col
    let line += 1
  endif

  " Wrap texts
  let indent_num = get(opt, 'indent', 0)
  let texts = [strpart(a:text, 0, max_width)]
  let rest_texts = iced#util#split_by_length(
        \ strpart(a:text, max_width),
        \ max_width - indent_num,
        \ )
  if indent_num > 0
    let spc = iced#util#char_repeat(indent_num, ' ')
    let rest_texts = map(rest_texts, {_, v -> printf('%s%s', spc, v)})
  endif
  let texts += rest_texts

  " To mask first 2 chars (:h popup-mask)
  let texts = map(texts, {_, v -> printf('  %s', v)})

  let align = get(opt, 'align', 'after')
  let popup_opts = {
        \ 'iced_context': {'last_col': col},
        \ 'highlight': get(opt, 'highlight', 'Comment'),
        \ 'mask': [[1, 2, 1, 1]],
        \ }
  if align ==# 'right'
    let popup_opts['col'] = 'right'
  else
    call self.inc_textprop_id()
    call prop_add(line('.'), col('$'), {
          \ 'id': self.textprop_id,
          \ 'type': s:textprop_type,
          \ })

    let popup_opts['textprop'] = s:textprop_type
    let popup_opts['textpropid'] = self.textprop_id
  endif

  if get(opt, 'auto_clear', v:false)
    let popup_opts['moved'] = 'any'
    let popup_opts['auto_close'] = v:false
  else
    let popup_opts['auto_close'] = v:false
  endif

  " NOTE: trim lines to show virtual text within a window
  let overflowed_lnum = self.popup.overflowed_lnum(texts)
  if overflowed_lnum >= 0
    let texts = texts[0:(len(texts) - overflowed_lnum - 5)]
  endif

  " Close virtual text window in the same location
  let winids_id = s:id_for_current_line()
  let winid = get(self.winids, winids_id)
  if ! empty(winid)
    call self.popup.close(winid)
    unlet self.winids[winids_id]
  endif

  " When auto_clear is enabled, store only one winid
  if get(opt, 'auto_clear', v:false)
    let self.winids = {}
  endif
  let self.winids[winids_id] = self.popup.open(texts, popup_opts)

  return self.winids[winids_id]
endfunction

function! s:vt.clear(...) abort
  call prop_clear(1, line('$'), {'type': s:textprop_type})

  for winid in values(self.winids)
    call self.popup.close(winid)
  endfor
  let self.winids = {}
endfunction

function! iced#component#virtual_text#vim#start(this) abort
  call iced#util#debug('start', 'vim virtual_text')
  let d = deepcopy(s:vt)
  let d['popup'] = a:this.popup
  let d['ex_cmd'] = a:this.ex_cmd
  return d
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
