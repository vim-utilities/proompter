#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter

""
"
function! proompter#base64#EncodeString(string) abort
  if !len(a:string)
    throw 'No string value'
  endif
  let l:string = shellescape(a:string)
  return system('base64 --wrap=0 < <(printf "%s" ' . l:string . ')')
endfunction

""
"
function! proompter#base64#DecodeString(string) abort
  if !len(a:string)
    throw 'No string value'
  endif
  let l:string = shellescape(a:string)
  return system('base64 --decode < <(printf "%s" ' . l:string . ')')
endfunction

""
"
function! proompter#base64#EncodeFile(path) abort
  if !len(a:path)
    throw 'No path value'
  endif
  let l:path = shellescape(a:path)
  return system('base64 --wrap=0 ' . l:path)
endfunction

""
" TODO: implement `flags` parser to have similar behavior to `writefile`
function! proompter#base64#DecodeToFile(string, path, flags = '') abort
  if !len(a:path)
    throw 'No path value'
  endif
  let l:path = shellescape(a:path)
  let l:string = shellescape(a:string)
  return system('base64 --decode < <(printf "%s" ' . l:string . ') > ' . l:path)
endfunction

" vim: expandtab
