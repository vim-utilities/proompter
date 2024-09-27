#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter


""
" Call `proompter#SendHighlightedText` and assign `prefix_input` to input
"
" Example:
"
" ```vim
" :69,420ProompterSelectionPrefixed 'Write some documentation about'
"
" :ProompterSelectionPrefixed 'What does this line do?'
" ```
command! -range -nargs=? ProompterSelectionPrefixed <line1>,<line2>call proompter#SendHighlightedText(<args>, g:proompter)

""
" Call `proompter#SendHighlightedText` with last/current visually selection
"
" Example:
"
" ```vim
" :69,420ProompterSelectionPrefixed
"
" :ProompterSelectionPrefixed
" ```
command! -range -nargs=? ProompterSelectionNow <line1>,<line2>call proompter#SendHighlightedText('', g:proompter)

