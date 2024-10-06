#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter

let g:proompter = {
      \   'select': {
      \     'model_name': 'codellama',
      \   },
      \   'api': {
      \     'url': 'http://127.0.0.1:11434/api/chat',
      \     'prompt_callbacks': {
      \       'chat': {
      \         'preamble': { configurations, state ->
      \           proompter#callback#prompt#chat#Preamble({
      \             'configurations': configurations,
      \             'state': state,
      \           })
      \         },
      \         'context': { configurations, state ->
      \           proompter#callback#prompt#chat#Context({
      \             'configurations': configurations,
      \             'state': state,
      \             'context_size': 5,
      \           })
      \         },
      \         'input': function('proompter#callback#prompt#chat#Input'),
      \         'post': { prompt_callbacks_data, configurations, state ->
      \           proompter#callback#prompt#chat#Post({
      \             'data': prompt_callbacks_data,
      \             'configurations': configurations,
      \             'state': state,
      \             'out_bufnr': v:null,
      \           })
      \         },
      \       },
      \       'generate': {
      \         'preamble': { configurations, state ->
      \           proompter#callback#prompt#generate#Preamble({
      \             'configurations': configurations,
      \             'state': state,
      \             'filetype': 'javascript',
      \             'history_tags': { 'start': '<HISTORY>', 'end': '</HISTORY>'},
      \             'input_tags': { 'start': '<PROOMPT>', 'end': '</PROOMPT>'},
      \             'response_tags': { 'start': '<RESPONSE>', 'end': '</RESPONSE>'},
      \           })
      \         },
      \         'context': { configurations, state ->
      \           proompter#callback#prompt#generate#Context({
      \             'configurations': configurations,
      \             'state': state,
      \             'context_size': 5,
      \             'history_tags': { 'start': '<HISTORY>', 'end': '</HISTORY>'},
      \             'input_tags': { 'start': '<PROOMPT>', 'end': '</PROOMPT>'},
      \             'response_tags': { 'start': '<RESPONSE>', 'end': '</RESPONSE>'},
      \           })
      \         },
      \         'input': { value, configurations, _state ->
      \           proompter#callback#prompt#generate#Input({
      \             'value': value,
      \             'configurations': configurations,
      \             'input_tags': { 'start': '<PROOMPT>', 'end': '</PROOMPT>'},
      \           })
      \         },
      \         'post': { prompt_callbacks_data, configurations, _state ->
      \           proompter#callback#prompt#generate#Post({
      \             'data': prompt_callbacks_data,
      \             'configurations': configurations,
      \             'out_bufnr': v:null,
      \           })
      \         },
      \       },
      \     },
      \   },
      \   'channel': {
      \     'address': '127.0.0.1:11435',
      \     'options': {
      \       'mode': 'raw',
      \       'callback': { _channel_response, api_response ->
      \         proompter#callback#channel#StreamToBuffer(
      \           api_response,
      \           g:proompter,
      \           g:proompter_state,
      \           v:null,
      \         )
      \       },
      \     },
      \   },
      \   'models': {
      \     'codellama': {
      \       'prompt_callbacks': {
      \         'chat': {},
      \         'generate': {},
      \       },
      \       'data': {
      \         'prompt': '',
      \         'raw': v:false,
      \         'stream': v:true,
      \       },
      \     },
      \   },
      \ }

" vim: expandtab
