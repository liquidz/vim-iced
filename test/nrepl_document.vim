let s:suite = themis#suite('iced.nrepl.document')
let s:assert = themis#helper('assert')
let s:ch = themis#helper('iced_channel')
let s:popup = themis#helper('iced_popup')
let s:io = themis#helper('iced_io')
let s:buf = themis#helper('iced_buffer')

function! s:setup() abort
  let g:vim_iced_home = expand('<sfile>:p:h')
  let g:iced_enable_popup_document = 'every'
  let g:iced_max_distance_for_auto_document = 2
  call s:io.mock()
  call s:popup.mock()
  call s:popup.close(0)
endfunction

function! s:teardown() abort
  unlet g:iced_enable_popup_document
  unlet g:iced_max_distance_for_auto_document
  call iced#buffer#document#close()
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
  call s:setup()
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

  call s:teardown()
endfunction

function! s:suite.document_with_spec_test() abort
  call s:setup()
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

  call s:teardown()
endfunction

function! s:suite.document_with_see_also_test() abort
  call s:setup()
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

  call s:teardown()
endfunction

function! s:suite.current_form_test() abort
  call s:setup()
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:relay', [{
        \ 'name': 'bar',
        \ 'ns': 'foo.core',
        \ 'arglists-str': "hello\nworld",
        \ }])})
  call s:buf.start_dummy(['(foo/bar| baz)'])

  call iced#nrepl#document#current_form()

  call s:assert.equals(s:io.get_last_args(), {
        \ 'echo': {'text': 'foo.core/bar hello world'},
        \ })

  call s:buf.stop_dummy()
  call s:teardown()
endfunction

function! s:suite.current_form_with_javadoc_test() abort
  call s:setup()
  call s:ch.mock({'status_value': 'open', 'relay': funcref('s:relay', [{
        \ 'member': 'bar' ,
        \ 'class': 'Foo' ,
        \ 'arglists-str': "args1\nargs2",
        \ 'returns': 'String',
        \ 'javadoc': 'dummy javadoc',
        \ }])})
  call s:buf.start_dummy(['(foo/bar| baz)'])

  call iced#nrepl#document#current_form()

  call s:assert.equals(s:io.get_last_args(), {
        \ 'echo': {'text': 'String Foo/bar args1 args2'},
        \ })

  let doc_texts = s:popup.get_last_texts()
  call map(doc_texts, {_, v -> trim(v)})
  call s:assert.equals(doc_texts, ['args1', 'args2'])

  call s:buf.stop_dummy()
  call s:teardown()
endfunction
