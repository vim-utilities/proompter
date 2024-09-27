#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
" Returns either dictionary with "headers" and "body" keys, or "part"
"
" WARN: either the proxy, or Vim, or API, or some combo are to blame for
" multi-part responses where headers and body trigger streaming callback
" twice!  First with headers, then second with headless body X-P
function! proompter#parse#HeaderAndBodyFromHTTPResponse(data) abort
  let l:pattern = "\n{"
  let l:index = stridx(a:data, l:pattern)
  if l:index == -1
    return { 'part': a:data }
  else
    return { 'headers': a:data[:l:index], 'body': a:data[l:index+1:] }
  endif
endfunction

" vim: expandtab
