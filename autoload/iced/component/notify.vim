let s:save_cpo = &cpoptions
set cpoptions&vim

let g:iced#notify#time = get(g:, 'iced#notify#time', 3000)
let g:iced#notify#max_height_rate = get(g:, 'iced#notify#max_height_rate', 0.5)
let g:iced#notify#max_width_rate = get(g:, 'iced#notify#max_width_rate', 0.4)

let s:notify = {
      \ 'popup': '',
      \ 'timer': '',
      \ 'timer_id': '',
      \ 'tmp_text': '',
      \ 'tmp_highlight': '',
      \ 'notifications': [],
      \ }

function! s:closed(id) abort dict
  let self.notifications = filter(self.notifications, {_, v -> v['id'] != a:id})
  let n = 0

  for x in self.notifications
    call self.popup.move(x['id'], {'line': n})
    let n += x['n'] + 1
  endfor
endfunction

function! s:collected(timer_id) abort dict
  let self.timer_id = ''
  if empty(trim(self.tmp_text)) | return | endif

  let wininfo = getwininfo(win_getid())[0]
  let win_width = wininfo['width']
  let max_length = float2nr(win_width * g:iced#notify#max_width_rate)

  let lines = split(self.tmp_text, '\r\?\n')
  let lines = map(lines, {_, v -> printf(' %s ', iced#util#shorten(v, max_length))})

  let row = 0
  for x in self.notifications
    let row += x['n'] + 1
  endfor

  let id = self.popup.open(lines, {
       \ 'auto_close': v:true,
       \ 'close_time': g:iced#notify#time,
       \ 'line': row,
       \ 'col': 'right',
       \ 'border': [],
       \ 'borderchars': ['-', '|', '-', '|', '+', '+', '+', '+'],
       \ 'highlight': self.tmp_highlight,
       \ 'callback': funcref('s:closed', [], self),
       \ })

  let self.notifications += [{'id': id, 'n': len(lines)}]
endfunction

function! s:notify.notify(text, ...) abort
  if ! g:iced_enable_notification | return | endif
  if empty(trim(a:text)) | return | endif

  let opt = get(a:, 1, {})

  if empty(self.timer_id)
    let self.tmp_text = a:text
    let self.tmp_highlight = get(opt, 'highlight', 'Comment')
    let self.timer_id = self.timer.start(100, funcref('s:collected', [], self))
  else
    "let self.tmp_text = printf("%s\n%s", self.tmp_text, a:text)
    let self.tmp_text .= a:text

    let hl = get(opt, 'highlight', '')
    if ! empty(hl)
      let self.tmp_highlight = hl
    endif
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
