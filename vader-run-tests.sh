#!/usr/bin/env bash
# https://github.com/junegunn/vader.vim

if ((CICD)); then
	vim -Nu <(cat <<VIMRC
	set rtp+=~/.vim/plugged/vader.vim
	set rtp+=.
VIMRC
) -c '+Vader! tests/**/*.vader'
else
	vim -Nu <(cat <<VIMRC
	set rtp+=~/.vim/plugged/vader.vim
	set rtp+=.
VIMRC
) -c 'Vader tests/**/*.vader'
fi

