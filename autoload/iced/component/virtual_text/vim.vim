let s:save_cpo = &cpoptions
set cpoptions&vim

let s:vt = {
      \ 'popup': '',
      \ 'ex_cmd': '',
      \ 'last_winid': v:null,
      \ 'textprop_id': 0,
      \ }

" Text property
let s:textprop_type = 'iced_virtual_text'
call prop_type_delete(s:textprop_type, {})
call prop_type_add(s:textprop_type, {})

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

  let self.textprop_id += 1
  call prop_add(line('.'), col('$'), {
        \ 'id': self.textprop_id,
        \ 'type': s:textprop_type,
        \ })

  let popup_opts = {
        \ 'iced_context': {'last_col': col},
        \ 'textprop': s:textprop_type,
        \ 'textpropid': self.textprop_id,
        \ 'highlight': get(opt, 'highlight', 'Comment'),
        \ 'mask': [[1, 2, 1, 1]],
        \ }
  if get(opt, 'auto_clear', v:false)
    let popup_opts['moved'] = 'any'
    let popup_opts['auto_close'] = v:false
  endif

  " NOTE: trim lines to show virtual text within a window
  let overflowed_lnum = self.popup.overflowed_lnum(texts)
  if overflowed_lnum >= 0
    let texts = texts[0:(len(texts) - overflowed_lnum - 5)]
  endif

  " Close last virtual text window if same position
  let ctx = self.popup.get_context(self.last_winid)
  if has_key(ctx, 'last_col') && col == ctx['last_col']
    call self.popup.close(self.last_winid)
  endif

  let self.last_winid = self.popup.open(texts, popup_opts)
  return self.last_winid
endfunction

function! s:vt.clear(...) abort
  call self.ex_cmd.silent_exe(':popupclear')
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
