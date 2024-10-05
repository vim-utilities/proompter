#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
" Return bufnr of new buffer after setting it up for logging proompts
"
" Parameter: {string|v:null} buffer_name - Name output buffer should use
"
" Attribution:
"
"   - https://stackoverflow.com/questions/8316139/how-to-set-the-default-to-unfolded-when-you-open-a-file
function! proompter#lib#GetOrMakeProomptBuffer(buffer_name) abort
  let l:old_bufnr = bufnr('%')

  let l:new_buffer_name = 'proompt-log.md'
  if type(a:buffer_name) == v:t_string
    let l:new_buffer_name = a:buffer_name
  endif

  let l:new_bufnr = bufnr(l:new_buffer_name)
  if l:new_bufnr != -1
    return l:new_bufnr
  endif

  new
  let l:new_bufnr = bufnr('%')

  setlocal buftype=nofile
  setlocal wrap
  setlocal filetype=markdown
  " setlocal readonly

  " silent! %foldopen

  execute 'file ' . l:new_buffer_name

  wincmd p
  return l:new_bufnr
endfunction

""
" Unlike `appendbufline` this first attempts to append to preexisting line,
" and only if new `content` contains a newline character (`\n`) will a newline
" be inserted into target buffer.
"
" Parameter: {number} `bufnr` Any available buffer to write to
" Parameter: {string} `content` Line, or lines separated by `\n`, to write
"
" See: {doc} :help getbufline()
" See: {doc} :help split()
" See: {doc} :help setbufline()
function! proompter#lib#ConcatenateWithLastLineOfBuffer(bufnr, content) abort
  let l:buffer_last_line = get(getbufline(a:bufnr, '$'), 0, '')
  let l:buffer_last_line .= a:content
  call setbufline(a:bufnr, '$', split(l:buffer_last_line, '\n', 1))
endfunction

""
"
function! proompter#lib#MessagesJSONRead(file_path, configurations = g:proompter, state = g:proompter_state) abort
  let l:file_path = expand(a:file_path)

  if !filereadable(l:file_path)
    throw 'Cannot read file at -> ' . a:file_path
  endif

  return json_decode(readfile(l:file_path))
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

  writefile(json_encode(l:messages), a:file_path, 's')
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
