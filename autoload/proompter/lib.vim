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
  if type(a:buffer_name) == type('')
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

  %foldopen!

  execute 'file ' . l:new_buffer_name

  wincmd p
  return l:new_bufnr
endfunction

" vim: expandtab
