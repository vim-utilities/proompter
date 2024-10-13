#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
" Returns either dictionary with "status" and "headers" dictionaries, as well
" as "body" with list of dictionaries parsed from HTTP response.
"
" Consumers must check length before attempting to use data, because reasons.
"
" WARN: either the proxy, or Vim, or API, or some combo are to blame for
" multi-part responses where headers and body trigger streaming callback
" twice!  First with headers, then second with headless body X-P
"
" See: {tests} tests/units/autoload_proompter_parse_http_Response.vader
function! proompter#parse#http#Response(data) abort
  let l:status = proompter#parse#http#response#ExtractStatus(a:data)
  let l:headers = proompter#parse#http#response#ExtractHeaders(a:data)
  let l:body = proompter#parse#http#response#ExtractJSONDicts(a:data)
  return { 'status': l:status, 'headers': l:headers, 'body': l:body }
endfunction

" vim: expandtab
