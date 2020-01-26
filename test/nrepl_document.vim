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

function! s:suite.javadoc_test() abort
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:relay', [{
        \ 'member': 'bar' ,
        \ 'class': 'Foo' ,
        \ 'arglists-str': "hello\nworld",
        \ 'doc': 'dummy doc',
        \ 'returns': 'dummy returns',
        \ 'javadoc': 'dummy javadoc',
        \ }])})
  let info = iced#buffer#document#init()

  let p = iced#nrepl#document#open('dummy')
  call iced#promise#wait(p)

  call s:assert.equals(getbufline(info['bufnr'], 1, '$'), [
        \ '*Foo/bar*',
        \ '  hello',
        \ '  world',
        \ '  dummy doc',
        \ '',
        \ g:iced#buffer#document#subsection_sep,
        \ '*Returns*',
        \ '  dummy returns',
        \ '',
        \ 'dummy javadoc',
        \ ])

  call iced#buffer#document#close()
endfunction

function! s:suite.document_with_spec_test() abort
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:relay', [{
        \ 'name': 'foo',
        \ 'ns': 'baz.core',
        \ 'doc': 'bar',
        \ 'spec': ['spec', ':args', 'hello', ':ret', 'world'],
        \ }])})
  let info = iced#buffer#document#init()

  let p = iced#nrepl#document#open('dummy')
  call iced#promise#wait(p)

  call s:assert.equals(getbufline(info['bufnr'], 1, '$'), [
        \ '*baz.core/foo*',
        \ '  bar',
        \ '',
        \ g:iced#buffer#document#subsection_sep,
        \ '*spec*',
        \ '  :args  hello',
        \ '  :ret   world',
        \ ])

  call iced#buffer#document#close()
endfunction

function! s:suite.document_with_see_also_test() abort
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:relay', [{
        \ 'name': 'foo',
        \ 'ns': 'baz.core',
        \ 'doc': 'bar',
        \ 'see-also': ['hello', 'world'],
        \ }])})
  let info = iced#buffer#document#init()

  let p = iced#nrepl#document#open('dummy')
  call iced#promise#wait(p)

  call s:assert.equals(getbufline(info['bufnr'], 1, '$'), [
        \ '*baz.core/foo*',
        \ '  bar',
        \ '',
        \ g:iced#buffer#document#subsection_sep,
        \ '*see-also*',
        \ ' - hello',
        \ ' - world',
        \ ])

  call iced#buffer#document#close()
endfunction
