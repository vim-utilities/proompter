#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter
" Version: 0.0.1
"
" License: This project is licensed based on use-case
"
" ## Commercial and/or proprietary use
"
" If a project is **either** commercial or (`||`) proprietary, then please
" contact the author for pricing and licensing options to make use of code and/or
" features from this repository.
"
" ---
"
" ## Non-commercial and FOSS use
"
" If a project is **both** non-commercial and (`&&`) published with a license
" compatible with AGPL-3.0, then it may utilize code from this repository under
" the following terms.
"
" ```
" Proxy traffic between Vim channel requests and Ollama LLM API
" Copyright (C) 2024 S0AndS0
"
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU Affero General Public License as published
" by the Free Software Foundation, version 3 of the License.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU Affero General Public License for more details.
"
" You should have received a copy of the GNU Affero General Public License
" along with this program.  If not, see <https://www.gnu.org/licenses/>.
" ```
"
" TODO: consider the following resources to improve plugin distribution
"
" - :help pi_getscript.txt

if exists('g:proompter__loaded') || v:version < 700
  finish
endif
let g:proompter__loaded = 1

""
" Configurations that may be overwritten
" Type: define__configurations
let s:defaults = {
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
      \       'callback': v:null,
      \     },
      \   },
      \   'models': {
      \     'codellama': {
      \       'prompt_callbacks': {
      \         'pre': v:null,
      \         'prompt': v:null,
      \         'input': v:null,
      \         'post': v:null,
      \       },
      \       'data': {
      \         'prompt': '',
      \         'raw': v:false,
      \         'stream': v:true,
      \       },
      \     },
      \   },
      \ }

""
" TODO: change `responses` to `history` and use `channel.id` somehow
" Per-buffer state this plugin uses for tracking Vim channel state and callback
" Type: define__proompter_state
let g:proompter_state = {
      \  'channel': v:null,
      \  'responses': [],
      \  'history': [],
      \ }

""
" Type Definition: {dictionary} define__configurations
"
" Property: {string} select.model_name - Key used to select into `models`
"
" Property: {string} api.url - Where channel proxy will forward requests to
"
" Property: {string} channel.address - See: {docs} :help channel-address
" Property: {string} channel.options - See: {docs} :help channel-open-options
" Property: {string} channel.options.mode - See: {docs} :help channel-mode
" Property: {function} channel.options.callback - See: {docs} :help channel-callback
"
" Property: {dictionary} models['model_name'].prompt_callbacks - All defined
"           callbacks in dictionary must return a string if defined.  These
"           callbacks _should_ have the same buffer scope as caller
" Property: {function} models['model_name'].prompt_callbacks.pre - takes no
"           arguments
" Property: {function} models['model_name'].prompt_callbacks.input - takes
"           string input from client
" Property: {function} models['model_name'].prompt_callbacks.post - takes
"           dictionary of strings with following keys; `pre`, `input`, and
"           `prompt` from `models['model_name'].data.prompt`
"
" Property: {dictionary} models['model_name'].data - 
" Property: {string} models['model_name'].data.prompt - 
" Property: {boolean} models['model_name'].data.raw - 
" Property: {boolean} models['model_name'].data.stream - 


""
" Type Definition: {dictionary} define__proompter_state
"
" Property: {define__proompter_state__response[]} responses - List of proxied
"           responses from LLM API, useful for streaming callbacks that are
"           triggered with body-less "head" responses, followed by second
"           event with headless "body" response
" Property: {define__proompter_state__response[]} history - List of parsed
"           input/output-s
" Property: {dictionary} channel - See: {docs} :help ch_info()


""
" Type Definition: {dictionary} define__proompter_state__response
"
" Property: {string} headers - New-line (`\r\n`) separated list of HTTP response headers
" Property: {string} body - Serialized JSON data
" Property: {string} text - JSON parsed value from `define__ollama_http_response__200.response`
"
" Examples:
"
" - Print headers of last response as list
"
" ```vim
" :echo split(copy(g:proompter_state.responses[-1].headers), "\r\n")
" ```
"
" - Print all `text` values from `g:proompter_state.responses` list and join into string
"
" ```vim
" :echo join(map(deepcopy(g:proompter_state.responses), { _k, v -> v.text }), '')
" ```


""
" Type Definition: {dictionary} define__ollama_http_response__200
"
" Property: {string} model - Name of LLM
" Property: {string} created_at - date/time stamp when output was sent
" Property: {string} response - token of text generated by LLM
" Property: {boolean} done - Set to `false` until LLM is done


""
" Merged dictionaries without mutation
" Parameter: {dict} defaults - Dictionary of default key/value pares
" Parameter: {...dict[]} override - Up to 20 dictionaries to merge into return
" Return: {dict}
" See: {docs} :help type()
" See: {link} https://vi.stackexchange.com/questions/20842/how-can-i-merge-two-dictionaries-in-vim
function! s:DictMerge(defaults, ...) abort
  let l:new = deepcopy(a:defaults)
  if a:0 == 0
    return l:new
  endif

  for l:override in a:000
    for [l:key, l:Value] in items(l:override)
      if type(l:Value) == type({}) && type(get(l:new, l:key)) == type({})
        let l:new[l:key] = s:DictMerge(l:new[l:key], l:Value)
      else
        let l:new[l:key] = l:Value
      endif
    endfor
  endfor

  return l:new
endfunction

""
" Merge global customization with defaults to `g:proompter`
" See: {docs} :help fnamemodify()
" See: {docs} :help readfile()
" See: {docs} :help json_decode()
if exists('g:proompter')
  if type(g:proompter) == type('') && fnamemodify(g:proompter, ':e') == 'json'
    let g:proompter = json_decode(join(readfile(g:proompter), ''))
  endif

  if type(g:proompter) == type({})
    let g:proompter = s:DictMerge(s:defaults, g:proompter)
  else
    let g:proompter = deepcopy(s:defaults)
  endif
else
  let g:proompter = deepcopy(s:defaults)
endif

" vim: expandtab
