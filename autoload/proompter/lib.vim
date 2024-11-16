#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter



""
" Reads file path as JSON data and returns a Vim |dictionary|, or |list|, data
" structure.
"
" Parameters:~
" - {path} |string| local JSON file to attempt reading and parsing
" - {configurations} |ProompterConfigurations| default `g:proompter`
" - {state} |ProompterState| default `g:proompter_state`
"
" @throws ProompterError `Cannot read file at -> {path}`
"
" @public
function! proompter#lib#MessagesJSONRead(path, configurations = g:proompter, state = g:proompter_state) abort
  let l:path = expand(a:path)

  if !filereadable(l:path)
    throw 'ProompterError Cannot read file at -> ' . a:path
  endif

  return json_decode(join(readfile(l:path, ''), '\n'))
endfunction

""
" Write `state.messages` from to file path
"
" Parameters:~
" - {path} |string| local JSON file to attempt writing
" - {configurations} |ProompterConfigurations| default `g:proompter`
" - {state} |ProompterState| default `g:proompter_state`
"
" @throws ProompterError `File exists but cannot be written to at -> {path}`
" @throws ProompterError `No messages to write`
"
" @public
function! proompter#lib#MessagesJSONWrite(path, configurations = g:proompter, state = g:proompter_state) abort
  let l:path = expand(a:path)

  let l:messages = []
  if filereadable(l:path)
    if !filewritable(l:path)
      throw 'ProompterError File exists but cannot be written to at -> ' . a:path
    endif

    let l:messages = json_decode(readfile(l:path))
  endif
  let l:messages = extend(l:messages, deepcopy(a:state.messages))

  if !len(l:messages)
    throw 'ProompterError No messages to write'
  endif

  call writefile([json_encode(l:messages)], a:path, 's')
endfunction

""
" Merged dictionaries without mutation and returns resulting |dictionary|
"
" Parameters:~
" - {defaults} |dictionary| of default key/value pares
" - {...} |list| of up to 20 dictionaries to merge into returned data
"
" See: documentation~
" |type()|
"
" See: links~
" - https://vi.stackexchange.com/questions/20842/how-can-i-merge-two-dictionaries-in-vim
"
" @public
function! proompter#lib#DictMerge(defaults, ...) abort
  let l:new = deepcopy(a:defaults)
  if a:0 == 0
    return l:new
  endif

  for l:override in a:000
    for [l:key, l:Value] in items(l:override)
      if type(l:Value) == v:t_dict && type(get(l:new, l:key)) == v:t_dict
        let l:new[l:key] = proompter#lib#DictMerge(l:new[l:key], l:Value)
      else
        let l:new[l:key] = l:Value
      endif
    endfor
  endfor

  return l:new
endfunction

" vim: expandtab
