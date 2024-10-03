#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
" Work around issues when `command -nargs=?` calls `function` with two
" optional parameters without any input.
"
" Parameters:
"   - {dictionary} defaults with "input" and "configuration" keys defined
"   - {string} ... Optional value passed from Vim `command -nargs=?`
"
" Warning: `FunctionReference` must have `range` or else it will be called for
" line in range passed to `s:DefaultSelectionArgs`
function! s:DefaultSelectionArgs(FunctionReference, defaults, ...) abort range
  if !exists('a:defaults.configuration')
    throw 'Undefined a:defaults.configuration'
  endif

  let l:input = get(a:000, 0, get(a:defaults, 'input', '""'))[1:-2]

  let l:command = a:firstline . ',' . a:lastline . 'call a:FunctionReference(l:input, a:defaults.configuration)'

  execute l:command
endfunction

""
" Call `proompter#SendHighlightedText` and assign `prefix_input` to input
"
" Example:
"
" ```vim
" :69,420ProompterSelection 'Write some documentation about'
"
" :ProompterSelection 'What does this line do?'
"
" :1337ProompterSelection
" ```
command! -range -nargs=? ProompterSelection <line1>,<line2>call s:DefaultSelectionArgs(function('proompter#SendHighlightedText'), { 'input': '', 'configuration': g:proompter }, <f-args>)

""
" Send arguments as a string to API, note quotes _should_ be honored
"
" Example:
"
" ```vim
" :ProompterSend Write a haiku about why Vim is the best text editor
" ```
command! -nargs=? ProompterSend call s:DefaultSelectionArgs(function('proompter#SendPrompt'), { 'input': '', 'configuration': g:proompter }, <f-args>)

""
" Quality of life commands to clear `g:proompter_state.messages`
command! ProompterMessagesClear let g:proompter_state.messages = []

""
" Save `g:proompter_state.messages` to file path
command! -nargs=1 -complete=file ProompterMessagesSave call proompter#lib#MessagesJSONWrite(<f-args>, g:proompter, g:proompter_state)

""
" Load and extend `g:proompter_state.messages` from file path
command! -nargs=1 -complete=file ProompterMessagesLoad call extend(g:proompter_state.messages, proompter#lib#MessagesJSONRead(<f-args>, g:proompter, g:proompter_state))

""
" Quality of life commands to load/unload currently configured model
command! ProompterLoad call proompter#load(g:proompter, g:proompter_state)
command! ProompterUnload call proompter#unload(g:proompter, g:proompter_state)

""
" Turns out closing a channel on Vim side propagates through proxy to API?!
command! ProompterCancel call proompter#cancel(g:proompter_state, g:proompter)

" vim: expandtab
