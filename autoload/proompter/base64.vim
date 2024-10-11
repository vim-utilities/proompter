#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter
"
" Note: pipes instead of process substitution is necessary to make GitHub
" Actions play nice with tests, however, for those using the Linux Subsystem
" on Windows or Cygwin there may be a performance hit :-(

""
"
function! proompter#base64#EncodeString(string) abort
  if !len(a:string)
    throw 'No string value'
  endif
  let l:string = shellescape(a:string)
  return system('printf "%s" ' . l:string . ' | base64 --wrap=0')
endfunction

""
"
function! proompter#base64#DecodeString(string) abort
  if !len(a:string)
    throw 'No string value'
  endif
  let l:string = shellescape(a:string)
  return system('printf "%s" ' . l:string . ' | base64 --decode')
endfunction

""
"
function! proompter#base64#EncodeFile(path) abort
  if !len(a:path)
    throw 'No path value'
  endif

  if !filereadable(a:path)
    throw 'Cannot read file -> ' . a:path
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

  if !filereadable(a:path)
    throw 'Cannot read file -> ' . a:path
  endif

  let l:path = shellescape(a:path)
  let l:string = shellescape(a:string)
  return system('printf "%s" ' . l:string . ' | base64 --decode > ' . l:path)
endfunction

" vim: expandtab
