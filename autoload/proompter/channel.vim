#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
"
" Parameters:~
" - {configurations} |ProompterConfigurations| default `g:proompter`
" - {state} |ProompterState| default `g:proompter_state`
"
" See: documentation~
" - |closure|
"
" See: tests~
" - tests/units/autoload_proompter_channel_CreateOptions.vader
"
" @public
function! proompter#channel#CreateOptions(configurations = g:proompter, state = g:proompter_state) abort
  let l:channel_options = deepcopy(a:configurations.channel.options)
  if type(get(l:channel_options, 'callback')) != v:t_func
    let l:bufnr = bufnr('%')
    let l:model_name = a:configurations.select.model_name
    ""
    " Access `a:configurations.models[l:model_name].data.stream` or assume `v:false`
    let l:stream = get(get(get(get(a:configurations, 'models', {}), model_name, {}), 'data', {}), 'stream', v:false)
    if l:stream
      let l:channel_options.callback = { _channel, api_response ->
            \   proompter#callback#channel#StreamToMessages(api_response, a:configurations, a:state)
            \ }
    else
      let l:channel_options.callback = { _channel, api_response ->
            \   proompter#callback#channel#CompleteToHistory(api_response, a:configurations, a:state)
            \ }
    endif
  endif
  return l:channel_options
endfunction

""
" Set `a:state.channel` if not already defined then return result of `ch_open(...)`
"
" Parameters:~
" - {configurations} |ProompterConfigurations| default `g:proompter`
" - {state} |ProompterState| default `g:proompter_state`
"
" @throws ProompterError when channel state is buffered with
" >
"   Channel cannot be written to and may have something reading from it
" <
" Warns: when `a:state.channel` is in a "fail" state
"
" Notes:
" - Will attempt to re-open channel if state is "closed"
" - We must use a closure to capture bufnr and pass it into callback
"
" See: tests~
" - tests/units/autoload_proompter_channel_GetOrSetOpen.vader
"
" @public
function! proompter#channel#GetOrSetOpen(configurations = g:proompter, state = g:proompter_state) abort
  if get(a:state, 'channel', v:null) == v:null
    let l:channel_options = proompter#channel#CreateOptions(a:configurations, a:state)
    let a:state.channel = ch_open(a:configurations.channel.address, l:channel_options)
    return a:state.channel
  endif

  let l:channel_status = ch_status(a:state.channel)
  if l:channel_status == 'fail'
    echoe 'Proompter: Failed to setup channel... Retrying'
    let l:channel_options = proompter#channel#CreateOptions(a:configurations, a:state)
    let a:state.channel = ch_open(a:configurations.channel.address, l:channel_options)
    return a:state.channel
  elseif l:channel_status == 'buffered'
    throw 'Proompter: Channel cannot be written to and may have something reading from it'
  elseif l:channel_status == 'closed'
    let l:channel_options = proompter#channel#CreateOptions(a:configurations, a:state)
    let a:state.channel = ch_open(a:configurations.channel.address, l:channel_options)
    return a:state.channel
  endif

  return a:state.channel
endfunction

" vim: expandtab
