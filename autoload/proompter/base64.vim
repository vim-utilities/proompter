#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter

""
"
function! proompter#base64#encode(string) abort
  if !len(a:string)
    throw 'No string value'
  endif
  let l:string = shellescape(a:string)
  return system('base64 --wrap=0 <<<' . l:string)
endfunction

""
"
function! proompter#base64#decode(string) abort
  if !len(a:string)
    throw 'No string value'
  endif
  return system('base64 --decode', a:string)
endfunction

" vim: expandtab
