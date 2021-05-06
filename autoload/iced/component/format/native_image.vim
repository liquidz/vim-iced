let s:save_cpo = &cpoptions
set cpoptions&vim

let s:Promise = vital#iced#import('Async.Promise')

let s:fmt = {
      \ 'command': '',
      \ 'sign': '',
      \ 'job': '',
      \ }

function! s:job_start_promise(job, resolve, code, d) abort
  let job_handle = a:job.start(a:d.command, {
       \ 'out_cb': funcref('s:out_cb', a:d),
       \ 'err_cb': funcref('s:err_cb', a:d),
       \ 'exit_cb': {v -> a:resolve(call('s:exit_cb', [a:job, v], a:d))}
       \ })
  call a:job.sendraw(job_handle, a:code)
  call a:job.close_stdin(job_handle)
endfunction

function! s:__format_finally(args) abort
  let current_bufnr = get(a:args, '_back_to_bufnr', bufnr('%'))
  let different_buffer = (current_bufnr != a:args.context.bufnr)
  if different_buffer | call iced#buffer#focus(a:args.context.bufnr) | endif

  setl modifiable
  call iced#util#restore_context(a:args.context)
  call a:args.sign_cmp.refresh({'signs': a:args.signs})

  if different_buffer | call iced#buffer#focus(current_bufnr) | endif
endfunction

function! s:out_cb(_, out) abort dict
  call extend(self.buf, iced#util#ensure_array(a:out))
endfunction

function! s:err_cb(_, out) abort dict
  if !empty(self.err) | return | endif
  let tmp = iced#util#ensure_array(a:out)
  if tmp == [''] | return | endif    " for neovim
  let self.err = tmp
endfunction

function! s:exit_cb(job, id) abort dict
  let self._finished = v:true

  let info = a:job.info(a:id)
  if !empty(self.err)
    if get(info, 'exitval', 0) != 0
      setl modifiable
      return iced#message#error_str(trim(join(self.err, ' ')))
    else
      call iced#message#warning_str(trim(join(self.err, ' ')))
    endif
  endif

  if has_key(self, 'callback')
    call self.callback(self)
  endif
endfunction

" format all {{{
function! s:__append_texts(lnum, texts) abort
  let lnum = a:lnum
  for txt in a:texts
    call append(lnum, txt)
    let lnum += 1
  endfor
  normal! dd
endfunction

function! s:__all(result) abort
  let res = deepcopy(a:result)
  let current_bufnr = bufnr('%')
  if current_bufnr != res.context.bufnr
    call iced#buffer#focus(res.context.bufnr)
  endif
  setl modifiable

  try
    let code = trim(join(res.buf, "\n"))
    if !empty(code)
      silent! execute "normal! i \<esc>x"
            \ | undojoin
            \ | %del
            \ | call s:__append_texts(0, split(code, '\r\?\n'))
    endif
  finally
    let res['back_to_bufnr'] = current_bufnr
    call s:__format_finally(res)
  endtry
endfunction

function! s:fmt.all() abort
  let context = iced#util#save_context()
  let codes = trim(join(getline(1, '$'), "\n"))
  if empty(codes)
    return iced#promise#reject('ng')
  endif

  " Disable editing until the formatting process is completed
  setl nomodifiable

  let d = {
        \ 'command': self.command,
        \ 'context': context,
        \ 'sign_cmp': self.sign,
        \ 'signs': copy(self.sign.list_in_buffer()),
        \ 'buf': [],
        \ 'err': [],
        \ 'callback': funcref('s:__all'),
        \ }
  return s:Promise.new({resolve -> s:job_start_promise(self.job, resolve, codes, d)})
endfunction " }}}

" format current form {{{
function! s:__current_form(result) abort
  let res = deepcopy(a:result)
  let current_bufnr = bufnr('%')
  if current_bufnr != res.context.bufnr
    call iced#buffer#focus(res.context.bufnr)
  endif
  setl modifiable

  try
    let code = trim(join(res.buf, "\n"))
    if !empty(code)
      let @@ = code
      silent normal! gv"0p
    endif
  finally
    let res['_back_to_bufnr'] = current_bufnr
    call s:__format_finally(res)
  endtry
endfunction

function! s:fmt.current_form() abort
  " must be captured before iced#paredit#get_current_top_something
  let context = iced#util#save_context()
  let codes = get(iced#paredit#get_current_top_something(), 'code', '')

  if empty(codes)
    call iced#message#warning('finding_code_error')
    return iced#promise#reject('ng')
  endif

  call winrestview(context.view)
  " Disable editing until the formatting process is completed
  setl nomodifiable

  let d = {
        \ 'command': self.command,
        \ 'context': context,
        \ 'sign_cmp': self.sign,
        \ 'signs': copy(self.sign.list_in_buffer()),
        \ 'buf': [],
        \ 'err': [],
        \ 'callback': funcref('s:__current_form'),
        \ }
  return s:Promise.new({resolve -> s:job_start_promise(self.job, resolve, codes, d)})
endfunction " }}}

" format minimal {{{
function! s:fmt.minimal(opt) abort
  let jump_to_its_match = get(a:opt, 'jump_to_its_match', v:true)

  let view = winsaveview()
  let reg_save = @@
  try
    if jump_to_its_match
      " NOTE: vim-sexp's slurp move cursor to tail of form
      normal! %
    endif

    let ncol = max([col('.')-1, 0])

    let char = getline('.')[ncol]
    if char ==# '['
      silent normal! va[y
    elseif char ==# '{'
      silent normal! va{y
    else
      silent normal! va(y
    endif
    let code = @@

    let d = {'buf': [], 'err': [], '_finished': v:false}
    let job_handle = self.job.start(self.command, {
          \ 'out_cb': funcref('s:out_cb', d),
          \ 'exit_cb': {v -> call('s:exit_cb', [self.job, v], d)},
          \ })
    call self.job.sendraw(job_handle, code)
    call self.job.close_stdin(job_handle)
    call iced#util#wait({-> d._finished == v:false}, 1000)

    let code = trim(join(d.buf, "\n"))
    if !empty(code)
      let @@ = iced#util#add_indent(ncol, code)
      silent normal! gv"0p
    endif
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction " }}}

" calculate indent level {{{
function! s:fmt.calculate_indent(lnum) abort
  let view = winsaveview()
  let reg_save = @@

  try
    let res = iced#paredit#get_current_top_something()
    let code = get(res, 'code', '')
    if trim(code) ==# ''
      return GetClojureIndent()
    endif

    let start_line = res['curpos'][1]
    let start_column = res['curpos'][2] - 1
    let target_lnum = a:lnum - start_line

    let i = 0
    let result = []
    for line in split(code, '\r\?\n')
      if i == target_lnum
        call add(result, '::__vim-iced-calc-indent__ ' . line)
      else
        call add(result, line)
      endif
      let i += 1
    endfor
    let code = join(result, "\n")

    let d = {'buf': [], 'err': [], '_finished': v:false}
    let job_handle = self.job.start(self.command, {
          \ 'out_cb': funcref('s:out_cb', d),
          \ 'exit_cb': {v -> call('s:exit_cb', [self.job, v], d)},
          \ })
    call self.job.sendraw(job_handle, code)
    call self.job.close_stdin(job_handle)
    call iced#util#wait({-> d._finished == v:false}, 1000)

    for line in d.buf
      let idx = stridx(line, '::__vim-iced-calc-indent__')
      if idx == -1 | continue | endif
      if line[idx-1] !=# ' '
        let idx -= 1
      endif

      return idx + start_column
    endfor

    return GetClojureIndent()
  finally
    let @@ = reg_save
    call winrestview(view)
  endtry
endfunction " }}}

" ==================================
" DO NOT USE THIS COMPONENT DIRECTLY
" ==================================
" See format#cljstyle or format#zprint component
function! iced#component#format#native_image#start(this) abort
  call iced#util#debug('start', 'format native-image')
  let d = deepcopy(s:fmt)
  let d.sign = a:this.sign
  let d.job = a:this.job
  return d
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
