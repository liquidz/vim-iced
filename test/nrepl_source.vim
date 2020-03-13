let s:suite = themis#suite('iced.nrepl.source')
let s:assert = themis#helper('assert')
let s:ch = themis#helper('iced_channel')
let s:popup = themis#helper('iced_popup')
let s:buf = themis#helper('iced_buffer')
let s:sys = themis#helper('iced_system_info')
let s:io = themis#helper('iced_io')

function! s:setup() abort
  let g:iced_enable_popup_document = 'every'
  call s:popup.mock()
  call s:popup.close(0)
  call s:sys.set_dummies()
  call s:io.mock() " to install `jet` automatically
  call iced#system#reset_component('job') " to use real `edn` component
  call iced#system#reset_component('edn')
endfunction

function! s:teardown() abort
  unlet g:iced_enable_popup_document
  call iced#buffer#document#close()
  call s:sys.clear_dummies()
endfunction

function! s:extract_definition_relay(msg) abort
  let op = a:msg['op']
  if op ==# 'eval'
    return {'status': ['done'], 'value': '#namespace[foo.core]'}
  elseif op ==# 'extract-definition'
    let file = printf('%s/baz.clj', s:sys.get_dummy_user_dir())
    let definition = printf( '{:definition {:definition "foo bar" :line-beg 1 :line-end 2 :col-beg 3 :file "%s" :name "hello"}}', file)
    return {'status': ['done'], 'definition': definition}
  else
    return {'status': ['done']}
  endif
endfunction

function! s:suite.popup_show_extract_definition_test() abort
  call s:setup()
  let g:iced_enable_enhanced_definition_extraction = v:true
  call s:ch.mock({
        \ 'status_value': 'open',
        \ 'relay': funcref('s:extract_definition_relay')})
  call s:buf.start_dummy(['d|ummy'])

  let p = iced#nrepl#source#popup_show('dummy')
  call iced#promise#wait(p)
  let texts = s:popup.get_last_texts()
  call s:assert.equals(texts, [';; file: /baz.clj:1 - 2', 'foo bar'])

  unlet g:iced_enable_enhanced_definition_extraction
  call s:buf.stop_dummy()
  call s:teardown()
endfunction
