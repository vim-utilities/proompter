#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter

""
" Label various patterns for matching supported number representations
"
" Properties:~
" - 'float' any signed or unsigned integer or float, with optional exponent >
"  1336
"  -419.68
"  -3.735929e+09
" <
" - `hex` case insensitive with optional `0x` prefix >
"   0xdeadbeef
" <
" - `octal` case insensitive with optional `0o` prefix >
"   0o145
" <
" - `binary` case insensitive with optional `0b` prefix >
"   0b110100100
" <
let s:number_types = {
      \   'float': '-?\d+(\.\d+(e(\+|-)\d+)?)',
      \   'hex': '(0x)?(\d|[abcdef])+',
      \   'integer': '-?\d+',
      \   'octal': '(0x)?[0-7]+',
      \   'binary': '(0b)?[0-1]+',
      \ }

let s:number_regexp = '\v^(' . join(values(s:number_types), '|') . ')$'

""
"
function! proompter#json#encode#Dictionary(data) abort
  if type(a:data) != v:t_dict
    throw 'ProompterError expected dictionary type but got -> `' . type(a:data) . '`'
  endif

  let l:result = '{'
  let l:data_length = len(a:data)
  let l:count = 0
  for [l:key, l:Value] in items(a:data)
    let l:result .= '"' . l:key . '"'
    let l:result .= ':'

    let l:value_type = type(l:Value)
    if l:value_type == v:t_dict
      let l:result .= proompter#json#encode#Dictionary(l:Value)
    elseif l:value_type == v:t_string
      if l:Value =~ s:number_regexp
        let l:result .= proompter#json#encode#Number(l:Value)
      else
        let l:result .= proompter#json#encode#String(l:Value)
      endif
    elseif l:value_type == v:t_list
      let l:result .= proompter#json#encode#List(l:Value)
    elseif l:value_type == v:t_none || l:value_type == v:t_bool
      let l:result .= proompter#json#encode#Literal(l:Value)
    elseif l:value_type == v:t_float || l:value_type == v:t_number
      let l:result .= proompter#json#encode#Number(l:Value)
    else
      throw 'ProompterError unknown value type for key `' . l:key . '`'
    endif

    let l:count += 1
    if l:count < l:data_length
      let l:result .= ','
    endif
  endfor
  let l:result .= '}'
  return l:result
endfunction

""
"
function! proompter#json#encode#List(data) abort
  if type(a:data) != v:t_list
    throw 'ProompterError expected list type but got -> `' . type(a:data) . '`'
  endif

  let l:result = '['
  let l:data_length = len(a:data)
  let l:count = 0
  for l:Value in a:data
    let l:value_type = type(l:Value)
    if l:value_type == v:t_dict
      let l:result .= proompter#json#encode#Dictionary(l:Value)
    elseif l:value_type == v:t_string
      if l:Value =~ s:number_regexp
        let l:result .= proompter#json#encode#Number(l:Value)
      else
        let l:result .= proompter#json#encode#String(l:Value)
      endif
    elseif l:value_type == v:t_list
      let l:result .= proompter#json#encode#List(l:Value)
    elseif l:value_type == v:t_none || l:value_type == v:t_bool
      let l:result .= proompter#json#encode#Literal(l:Value)
    elseif l:value_type == v:t_float || l:value_type == v:t_number
      let l:result .= proompter#json#encode#Number(l:Value)
    else
      throw 'ProompterError unknown value type for index `' . l:count . '`'
    endif

    let l:count += 1
    if l:count < l:data_length
      let l:result .= ','
    endif
  endfor
  let l:result .= ']'
  return l:result
endfunction

""
"
function! proompter#json#encode#Literal(data) abort
  if a:data == v:null
    return 'null'
  elseif a:data == v:true
    return 'true'
  elseif a:data == v:false
    return 'false'
  endif
  throw 'ProompterError failed to parse data as literal -> ' . a:data
endfunction

""
" Returns a |string| typed version of input `data` and attempts to work-around
" issues of floating point numbers truncating digits by default.
"
" See: links~
" - https://en.wikipedia.org/wiki/IEEE_754#Basic_and_interchange_formats
" - https://github.com/vim/vim/pull/15902
function! proompter#json#encode#Number(data) abort
  let l:result = v:null

  let l:data_type = type(a:data)
  if l:data_type == v:t_float
    if v:numbersize == 64
      let l:result = printf('%.16f', a:data)
    elseif v:numbersize == 32
      let l:result = printf('%.7f', a:data)
    else
      let l:result = printf('%f', a:data)
    endif
  elseif l:data_type == v:t_number
    let l:result = printf('%i', a:data)
  elseif a:data =~ '\v^' . s:number_types.float . '$'
    let l:result = printf('%s', a:data)
  elseif a:data =~ '\v^' . s:number_types.hex . '$'
    let l:result = printf('%i', a:data)
  elseif a:data =~ '\v^' . s:number_types.integer . '$'
    let l:result = a:data
  elseif a:data =~ '\v^' . s:number_types.octal . '$'
    let l:result = printf('%i', a:data)
  elseif a:data =~ '\v^' . s:number_types.binary . '$'
    let l:result = printf('%i', a:data)
  endif

  if l:result == v:null
    throw 'ProompterError failed to parse data as number -> ' . a:data
  endif

  return l:result
endfunction

""
" Wraps `data` with double-quotes adding escaping back-slash(s) (`\`), were
" necessary, and returns a |string|
function! proompter#json#encode#String(data) abort
  let l:result = '"'

  let l:index = 0
  let l:data_length = len(a:data)
  while l:index < l:data_length
    let l:character = a:data[l:index]
    let l:character_code = printf('0x%02x', char2nr(l:character))
    let l:character_escape = get(g:proompter#json#Character_Escapes, l:character_code, v:null)
    if l:character_escape == v:null
      let l:result .= l:character
    else
      let l:result .= l:character_escape.encode
    endif
    let l:index += 1
  endwhile

  let l:result .= '"'
  return l:result
endfunction

" vim: expandtab
