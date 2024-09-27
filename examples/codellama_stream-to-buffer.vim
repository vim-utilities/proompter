#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter

let g:proompter = {
      \   'select': {
      \     'model_name': 'codellama',
      \   },
      \   'api': {
      \     'url': 'http://127.0.0.1:11434/api/generate',
      \   },
      \   'channel': {
      \     'address': '127.0.0.1:11435',
      \     'options': {
      \       'mode': 'raw',
      \       'callback': { channel_response, api_response ->
      \         proompter#callback#channel#StreamToBuffer({
      \           'channel_response': channel_response,
      \           'api_response': api_response,
      \           'response_tag': 'RESPONSE',
      \           'out_bufnr': v:null,
      \         })
      \       },
      \     },
      \   },
      \   'models': {
      \     'codellama': {
      \       'prompt_callbacks': {
      \         'pre': { ->
      \           proompter#callback#prompt#Pre({
      \             'context_size': 5,
      \             'filetype': 'javascript',
      \             'history_tags': { 'start': '<HISTORY>', 'end': '</HISTORY>'},
      \             'input_tags': { 'start': '<PROOMPT>', 'end': '</PROOMPT>'},
      \           })
      \         },
      \         'input': { value ->
      \           proompter#callback#prompt#Input({
      \             'value': value,
      \             'input_tag': 'PROOMPT',
      \           })
      \         },
      \         'post': { prompt_callbacks_data ->
      \           proompter#callback#prompt#Post({
      \             'data': prompt_callbacks_data,
      \             'context_size': 5,
      \             'history_tags': { 'start': '<HISTORY>', 'end': '</HISTORY>'},
      \             'out_bufnr': v:null,
      \           })
      \         },
      \       },
      \       'data': {
      \         'prompt': '',
      \         'raw': v:false,
      \         'stream': v:true,
      \       },
      \     },
      \   },
      \ }
