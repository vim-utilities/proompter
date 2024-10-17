#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
" Normalize response from Ollama API `/api/chat` and `/api/generate` endpoints 
"
" Parameters:~
" - {data} |dictionary| should conform to expectations of either
"   |APIResponseChat| or |APIResponseGenerate|
"
" Returns:~
" |APIResponseNormalized| data structure
"
" @public
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

""
" @dict APIResponseNormalized
"
" Merged data from |APIResponseChat| and |APIResponseGenerate|
"
" |dictionary| with shape similar to >
"   {
"     "model": "llama3.2",
"     "created_at": "2023-08-04T08:52:19.385406455-07:00",
"     "message": {
"       "role": "assistant",
"       "content": "The",
"       "images": v:null
"       "tool_calls": v:null
"     },
"     "context": v:null,
"     "done": v:false,
"     "done_reason": v:null,
"   }
" <

""
" @dict APIResponseChat
"
" Example: /api/chat~ >
"   {
"     "model": "llama3.2",
"     "created_at": "2023-12-12T14:13:43.416799Z",
"     "message": {
"       "role": "assistant",
"       "content": "Hello! How are you today?"
"     },
"     "done": true,
"     "total_duration": 5191566416,
"     "load_duration": 2154458,
"     "prompt_eval_count": 26,
"     "prompt_eval_duration": 383809000,
"     "eval_count": 298,
"     "eval_duration": 4799921000
"   }
" <
"
" Attribution:
" - https://github.com/ollama/ollama/blob/main/docs/api.md#chat-request-with-history

""
" @dict APIResponseGenerate
"
" Example: /api/generate~ >
"   {
"     "model": "llama3.2",
"     "created_at": "2023-08-04T19:22:45.499127Z",
"     "response": "The sky is blue because it is the color of the sky.",
"     "done": true,
"     "context": [1, 2, 3],
"     "total_duration": 4935886791,
"     "load_duration": 534986708,
"     "prompt_eval_count": 26,
"     "prompt_eval_duration": 107345000,
"     "eval_count": 237,
"     "eval_duration": 4289432000
"   }
" <

" vim: expandtab
