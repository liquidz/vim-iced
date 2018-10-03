let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#iced#new()
let s:S = s:V.import('Data.String')

function! s:src_skeleton_list(ns) abort
  return [printf('(ns %s)', a:ns)]
endfunction

function! s:clj_test_skeleton_list(ns) abort
  let src_ns = iced#nrepl#ns#transition#cycle(a:ns)
  return [
      \ printf('(ns %s', a:ns),
      \ '  (:require [clojure.test :as t]',
      \ printf('            [%s :as sut]))', src_ns),
      \ ]
endfunction

function! s:cljs_test_skeleton_list(ns) abort
  let src_ns = iced#nrepl#ns#transition#cycle(a:ns)
  return [
      \ printf('(ns %s', a:ns),
      \ '  (:require [cljs.test :as t :include-macros true]',
      \ printf('            [%s :as sut]))', src_ns),
      \ ]
endfunction

function! s:cljc_test_skeleton_list(ns) abort
  let src_ns = iced#nrepl#ns#transition#cycle(a:ns)
  return [
      \ printf('(ns %s', a:ns),
      \ '  (:require #?@(:clj  [[clojure.test :as t]',
      \ printf('                       [%s :as sut]]', src_ns),
      \ '                :cljs [[cljs.test :as t :include-macros true]',
      \ printf('                       [%s :as sut]])))', src_ns),
      \ ]
endfunction

function! iced#skeleton#new() abort
  if !iced#nrepl#is_connected()
    return
  endif

  let path = expand('%:p:r')
  let user_dir = iced#nrepl#system#user_dir()
  let separator = iced#nrepl#system#separator()

  if empty(user_dir) || stridx(path, user_dir) != 0
    return
  endif

  let path = strpart(path, len(user_dir)+1)
  let ns = substitute(join(split(path, separator)[1:], '.'), '_', '-', 'g')

  let lines = []
  let ext = expand('%:e')
  if !s:S.ends_with(ns, '-test')
    let lines = s:src_skeleton_list(ns)
  elseif ext ==# 'cljs'
    let lines = s:cljs_test_skeleton_list(ns)
  elseif ext ==# 'cljc'
    let lines = s:cljc_test_skeleton_list(ns)
  else
    let lines = s:clj_test_skeleton_list(ns)
  endif

  for line in reverse(lines)
    call append(0, line)
  endfor
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
