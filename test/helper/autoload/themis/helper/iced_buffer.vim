let s:save_cpo = &cpoptions
set cpoptions&vim

let s:helper = {'started': v:false}

function! s:helper.start_dummy(lines) abort
  vnew
  setl buftype=nofile
  setl nobuflisted

  let i = 1
  let cursor_pos = [1, 1]
  for line in a:lines
    let n = stridx(line, '|')
    if n != -1
      let cursor_pos = [i, n+1]
    endif
    call setline(i, substitute(line, '|', '', 'g'))
    let i = i+1
  endfor

  call cursor(cursor_pos[0], cursor_pos[1])

  let self['started'] = v:true
endfunction

function! s:helper.get_lines() abort
  return getline(line('^'), line('$'))
endfunction

function! s:helper.get_texts() abort
  return trim(join(getline(line('^'), line('$')), "\n"))
endfunction

function! s:helper.test_curpos(lines) abort
  let i = 1
  let current_pos = getcurpos()
  let cursor_pos = [1, 1]
  let expected_lines = []
  for line in a:lines
    let n = stridx(line, '|')
    if n != -1
      let cursor_pos = [i, n+1]
    endif
    call add(expected_lines, substitute(line, '|', '', 'g'))
    let i = i+1
  endfor

  return self.get_texts() ==# trim(join(expected_lines, "\n"))
        \ && cursor_pos[0] == current_pos[1]
        \ && cursor_pos[1] == current_pos[2]
endfunction

function! s:helper.stop_dummy() abort
  if has_key(self, 'started') && self['started']
    exe ':q'
    unlet self['started']
  endif
endfunction

function! themis#helper#iced_buffer#new(runner) abort
  return deepcopy(s:helper)
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
