#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter



""
" Return bufnr of new buffer after setting it up for logging proompts
"
" Parameters:~
" - {buffer_name} |string| or |v:null| name output buffer should use
"
" Attribution:~
" - https://stackoverflow.com/questions/8316139/how-to-set-the-default-to-unfolded-when-you-open-a-file
"
" @public
function! proompter#buffer#MakeProomptLog(buffer_name) abort
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
" Parameters:~
" - {bufnr} |number| any available buffer to write to
" - {content} |string| line, or lines separated by `\n`, to write
"
" See: documentation~
" - |getbufline()|
" - |split()|
" - |setbufline()|
"
" See: tests~
" - tests/units/autoload_proompter_buffer_ConcatinateWithLastLine.vader
"
" @public
function! proompter#buffer#ConcatenateWithLastLine(bufnr, content) abort
  let l:buffer_last_line = get(getbufline(a:bufnr, '$'), 0, '')
  let l:buffer_last_line .= a:content
  call setbufline(a:bufnr, '$', split(l:buffer_last_line, '\n', 1))
endfunction


" vim: expandtab
