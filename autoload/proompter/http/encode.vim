#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
" Craft HTTP POST with `data` encoded as JSON in body and path pointing to API
"
" Parameter: {dict} data - Body payload that will be POST-ed
" Parameter: {define__configurations} configurations - Reads properties to
"            build POST request for proxy
"
" See: {tests} tests/units/autoload_proompter_http_encode_Post.vader
function! proompter#http#encode#Post(data, configurations = g:proompter) abort
  let l:json = json_encode(a:data)

  return join([
        \   'POST ' . a:configurations.api.url . ' HTTP/1.1',
        \   'Host: ' . a:configurations.channel.address,
        \   'Content-Type: application/json',
        \   'Content-Length: ' . strlen(l:json),
        \   '',
        \   l:json,
        \ ], "\r\n")
endfunction

" vim: expandtab
