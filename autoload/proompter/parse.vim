#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
" Normalize response from Ollama API `/api/chat` and `/api/generate` endpoints 
"
" Returns: dictionary with shape similar to
"
" ```
" {
"   "model": "llama3.2",
"   "created_at": "2023-08-04T08:52:19.385406455-07:00",
"   "message": {
"     "role": "assistant",
"     "content": "The",
"     "images": v:null
"   },
"   "context": v:null,
"   "done": v:false,
"   "done_reason": v:null,
" }
" ```
"
" Attribution:
"
" - https://github.com/ollama/ollama/blob/main/docs/api.md#chat-request-with-history
"
" Recognized API endpoint from `g:proompter.api.url`;
"
" - `/api/generate` returns {"response": "{string} }
"
" - `/api/chat` returns either;
"   - {"message": {"role":"assistant"}, {"content":"{string}"}, {"images":null}}
"   - {"message": {"role":"assistant"}, {"content":"{string}"}, {"images":["Base64"]}}
function! proompter#parse#MessageOrResponseFromAPI(data) abort
  let l:result = {
        \   'model': a:data.model,
        \   'created_at': a:data.created_at,
        \   'message': {
        \     'role': 'assistant',
        \     'content': get(a:data, 'response', get(get(a:data, 'message', {}), 'content', '')),
        \     'images': get(a:data, 'images', v:null),
        \     'tool_calls': get(a:data, 'tool_calls', get(get(a:data, 'message', {}), 'tool_calls', v:null)),
        \   },
        \   'context': get(a:data, 'context', v:null),
        \   'done': a:data.done,
        \   'done_reason': get(a:data, 'done_reason', v:null),
        \ }

  return l:result
endfunction

" vim: expandtab
