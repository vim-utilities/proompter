#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
"
" Parameter: {define__configurations} configurations
" Parameter: {define__proompter_state} state
"
" See: {docs} :help closure
function! proompter#channel#CreateOptions(configurations = g:proompter, state = g:proompter_state) abort
  let l:channel_options = deepcopy(a:configurations.channel.options)
  if type(get(l:channel_options, 'callback')) != v:t_func
    let l:bufnr = bufnr('%')
    let l:stream = a:configurations.models[a:configurations.select.model_name].data.stream
    if l:stream
      let l:channel_options.callback = { _channel, api_response ->
            \   proompter#callback#channel#StreamToHistory(api_response, a:configurations, a:state)
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
" Parameter: {define__configurations} configurations
" Parameter: {define__proompter_state} state
"
" Throw: when `a:state.channel` is in a "buffered" state
" Warns: when `a:state.channel` is in a "fail" state
"
" Notes:
"
" - Will attempt to re-open channel if state is "closed"
" - We must use a closure to capture bufnr and pass it into callback
function! proompter#channel#GetOrSetOpen(configurations = g:proompter, state = g:proompter_state) abort
  if a:state.channel == v:null
    let l:channel_options = proompter#channel#CreateOptions(a:configurations)
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
