#!/usr/bin/env vim
" proompter.vim - Provide integration with local Ollama LLM API
" Maintainer: S0AndS0 <https://github.com/S0AndS0>
" URL: https://github.com/vim-utilities/proompter

""
" When in normal mode we can now cancel a prompt via <leader>pc
noremap <leader>pc :call proompter#cancel(g:proompter_state, g:proompter)<CR>

""
" When in visual/select modes we can prompt a selection with <leader>ps
vnoremap <leader>ps :<C-U>call proompter#SendHighlightedText('', g:proompter)<CR>

" vim: expandtab
