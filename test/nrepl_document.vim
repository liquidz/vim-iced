let s:suite = themis#suite('iced.nrepl.document')
let s:assert = themis#helper('assert')
let s:ch = themis#helper('iced_channel')
let s:popup = themis#helper('iced_popup')

function! s:setup() abort
  let g:iced_enable_popup_document = 'full'
  call s:popup.mock()
endfunction

function! s:teardown() abort
  unlet g:iced_enable_popup_document
endfunction

function! s:relay(info_base, msg) abort
  let op = a:msg['op']
  if op ==# 'eval'
    return {'status': ['done'], 'value': '#namespace[foo.core]'}
  elseif op ==# 'info'
    let resp = copy(a:info_base)
    let resp['status'] = ['done']
    return resp
  else
    return {'status': ['done']}
  endif
endfunction

function! s:suite.popup_open_cljdoc_test() abort
  call s:setup()
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:relay', [{
        \ 'name': 'bar',
        \ 'ns': 'foo.core',
        \ 'doc': 'baz',
        \ }])})

  let p = iced#nrepl#document#popup_open('dummy')
  call iced#promise#wait(p)

  let doc_texts = s:popup.get_last_texts()
  call map(doc_texts, {_, v -> trim(v)})
  call s:assert.equals(doc_texts, ['*foo.core/bar*', 'baz'])

  call s:teardown()
endfunction

function! s:suite.popup_open_cljdoc_with_empty_doc_test() abort
  call s:setup()
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:relay', [{
        \ 'name': 'baz',
        \ 'ns': 'bar.core',
        \ 'doc': [],
        \ }])})

  let p = iced#nrepl#document#popup_open('dummy')
  call iced#promise#wait(p)

  let doc_texts = s:popup.get_last_texts()
  call map(doc_texts, {_, v -> trim(v)})
  call s:assert.equals(doc_texts, ['*bar.core/baz*', 'Not documented.'])

  call s:teardown()
endfunction
