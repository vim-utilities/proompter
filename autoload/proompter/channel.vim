#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
"
" Parameter: {define__configurations} configurations
"
" See: {docs} :help closure
function! proompter#channel#CreateOptions(configurations = g:proompter) abort
  let l:channel_options = deepcopy(a:configurations.channel.options)
  if type(l:channel_options.callback) != type(function("tr"))
    let l:bufnr = bufnr('%')
    let l:stream = a:configurations.models[a:configurations.select.model_name].data.stream
    if l:stream
      let l:channel_options.callback = {channel, response -> proompter#callback#channel#StreamToHistory(channel, response, l:bufnr)}
    else
      let l:channel_options.callback = {channel, response -> proompter#callback#channel#CompleteToHistory(channel, response, l:bufnr)}
    endif
  endif
  return l:channel_options
endfunction

""
" Set `g:proompter_state.channel` if not already defined then return result of `ch_open(...)`
"
" Parameter: {define__configurations} configurations
"
" Throw: when `g:proompter_state.channel` is in a "buffered" state
" Warns: when `g:proompter_state.channel` is in a "fail" state
"
" Notes:
"
" - Will attempt to re-open channel if state is "closed"
" - We must use a closure to capture bufnr and pass it into callback
function! proompter#channel#GetOrSetOpen(configurations = g:proompter) abort
  if g:proompter_state.channel == v:null
    let l:channel_options = proompter#channel#CreateOptions(a:configurations)
    let g:proompter_state.channel = ch_open(a:configurations.channel.address, l:channel_options)
    return g:proompter_state.channel
  endif

  let l:channel_status = ch_status(g:proompter_state.channel)
  if l:channel_status == 'fail'
    echoe 'Proompter: Failed to setup channel... Retrying'
    let l:channel_options = proompter#channel#CreateOptions(a:configurations)
    let g:proompter_state.channel = ch_open(a:configurations.channel.address, l:channel_options)
    return g:proompter_state.channel
  elseif l:channel_status == 'buffered'
    throw 'Proompter: Channel cannot be written to and may have something reading from it'
  elseif l:channel_status == 'closed'
    let l:channel_options = proompter#channel#CreateOptions(a:configurations)
    let g:proompter_state.channel = ch_open(a:configurations.channel.address, l:channel_options)
    return g:proompter_state.channel
  endif

  return g:proompter_state.channel
endfunction

" vim: expandtab
