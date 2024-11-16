#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


" See: Vim source~
"
" - https://github.com/vim/vim/blob/v9.1.0821/src/json.c#L186-L200
let g:proompter#json#Character_Escapes = {
      \   '0x08': { 'decode': "\b", 'encode': '\b' },
      \   '0x09': { 'decode': "\t", 'encode': '\t' },
      \   '0x0a': { 'decode': "\n", 'encode': '\n' },
      \   '0x0c': { 'decode': "\f", 'encode': '\f' },
      \   '0x0d': { 'decode': "\r", 'encode': '\r' },
      \   '0x22': { 'decode': "\"", 'encode': '\"' },
      \   '0x5c': { 'decode': "\\", 'encode': '\\' },
      \ }



""
" Return |dictionary| or |list| parsed from `data` starting at `index`
"
" Parameters:~
" - {data} |string|
" - {index} |Number| default `0`
"
" @public
function! proompter#json#Parse(data, index = 0) abort
  let l:character = a:data[a:index]
  if l:character == '{'
    let l:result = proompter#json#decode#Dictionary(a:data, a:index)
    return l:result.value
  elseif l:character == '['
    let l:result = proompter#json#decode#List(a:data, a:index)
    return l:result.value
  endif
  throw 'ProompterError expected `{` or `[` but got `' . l:character . '` at `' . a:index . '`'
endfunction

function! proompter#json#Stringify(data) abort
  if type(a:data) == v:t_dict
    return proompter#json#encode#Dictionary(a:data)
  elseif type(a:data) == v:t_list
    return proompter#json#encode#List(a:data)
  endif

  throw 'ProompterError expected type `v:t_dict` or `v:t_list` but got `' . type(a:data) . '`'
endfunction

" vim: expandtab
