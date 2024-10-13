#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
"
function! proompter#lib#MessagesJSONRead(file_path, configurations = g:proompter, state = g:proompter_state) abort
  let l:file_path = expand(a:file_path)

  if !filereadable(l:file_path)
    throw 'Cannot read file at -> ' . a:file_path
  endif

  return json_decode(join(readfile(l:file_path, ''), '\n'))
endfunction

""
"
function! proompter#lib#MessagesJSONWrite(file_path, configurations = g:proompter, state = g:proompter_state) abort
  let l:file_path = expand(a:file_path)

  let l:messages = []
  if filereadable(l:file_path)
    if !filewritable(l:file_path)
      throw 'File exists but cannot be written to at -> ' . a:file_path
    endif

    let l:messages = json_decode(readfile(l:file_path))
  endif
  let l:messages = extend(l:messages, deepcopy(a:state.messages))

  if !len(l:messages)
    throw 'No messages to write'
  endif

  call writefile([json_encode(l:messages)], a:file_path, 's')
endfunction

""
" Merged dictionaries without mutation
" Parameter: {dict} defaults - Dictionary of default key/value pares
" Parameter: {...dict[]} override - Up to 20 dictionaries to merge into return
" Return: {dict}
" See: {docs} :help type()
" See: {link} https://vi.stackexchange.com/questions/20842/how-can-i-merge-two-dictionaries-in-vim
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
