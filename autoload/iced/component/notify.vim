let s:save_cpo = &cpoptions
set cpoptions&vim

let g:iced#notify#max_height_rate = get(g:, 'iced#notify#max_height_rate', 0.2)
let g:iced#notify#max_width_rate = get(g:, 'iced#notify#max_width_rate', 0.3)

let s:notify = {
      \ 'popup': '',
      \ 'timer': '',
      \ 'timer_id': '',
      \ 'texts': [],
      \ 'tmp_texts': [],
      \ 'tmp_title': '',
      \ 'popup_id': '',
      \ }

function! s:collected(timer_id) abort dict
  let self.timer_id = ''
  if empty(self.tmp_texts) | return | endif

  let wininfo = getwininfo(win_getid())[0]
  let win_width = wininfo['width']
  let win_height = wininfo['height']
  let max_width = float2nr(win_width * g:iced#notify#max_width_rate)
  let max_height = float2nr(win_height * g:iced#notify#max_height_rate)

  let lines = map(self.tmp_texts, {_, v -> iced#util#shorten(v, max_width)})
  if len(lines) > max_height - 1
    let lines = lines[((max_height - 1) * -1):]
  endif
  let lines = [printf(';; ---- %s ----', self.tmp_title)] + lines

  let self.texts += lines
  if len(self.texts) > max_height
    let self.texts = self.texts[(max_height * -1):]
  endif

  if empty(self.popup_id) || winbufnr(self.popup_id) == -1
    let popup_opt = {
          \ 'auto_close': v:false,
          \ 'moved': 'any',
          \ 'width': max_width + 4,
          \ 'line': (winline() <= win_height / 2) ? 'top' : 'bottom',
          \ 'col': 'right',
          \ 'highlight': 'TabLine',
          \ 'filetype': 'clojure',
          \ }

    let self.popup_id = self.popup.open(copy(self.texts), popup_opt)
  else
    call self.popup.settext(self.popup_id, copy(self.texts))
  endif
endfunction

function! s:notify.notify(text, ...) abort
  if ! g:iced_enable_notification | return | endif
  if empty(trim(a:text)) | return | endif

  let opt = get(a:, 1, {})

  if empty(self.timer_id)
    let self.tmp_texts = [a:text]
    let self.tmp_title = get(opt, 'title', 'Notification')
    let self.timer_id = self.timer.start(100, funcref('s:collected', [], self))
  else
    let self.tmp_texts += [a:text]
    call self.timer.stop(self.timer_id)
    let self.timer_id = self.timer.start(100, funcref('s:collected', [], self))
  endif
endfunction

function! iced#component#notify#start(this) abort
  call iced#util#debug('start', 'notify')
  let s:notify.popup = a:this['popup']
  let s:notify.timer = a:this['timer']
  return s:notify
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
