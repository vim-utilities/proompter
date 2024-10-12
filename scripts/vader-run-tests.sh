#!/usr/bin/env bash

###
# Dependencies
#
# ## Arch (BTW™)
#
# - vim
# - python
#
## Vim (BTW™)
#
# - Vader -- https://github.com/junegunn/vader.vim
#
##

## Find true directory this script resides in
__SOURCE__="${BASH_SOURCE[0]}"
while [[ -h "${__SOURCE__}" ]]; do
	__SOURCE__="$(find "${__SOURCE__}" -type l -ls | sed -n 's@^.* -> \(.*\)@\1@p')"
done
__NAME__="${__SOURCE__##*/}"
__DIR__="$(cd -P "$(dirname "${__SOURCE__}")" && pwd)"
# __G_DIR__="$(dirname "${__DIR__}")"
__AUTHOR__='S0AndS0'
__DESCRIPTION__='Run mock Ollama API, then Vader unit tests, and clean-up'

_test='units'
_proxy_host='127.0.0.1'
_proxy_port=41968
_proxy_log="$(mktemp --quiet)"

_proxy_exec="${__DIR__}/proompter-channel-proxy.py"
_proxy_args=(--host "${_proxy_host}" --port "${_proxy_port}" --mock --verbose)

usage() {
	local _messages=("${@}")

	cat <<EOF
--help
	Print this message and exit


--cicd
	Run tests as if in non-interactive terminal session


--kill    --kill-proxy
	Attempt to stop proxy after tests


--host <STRING>
	Default: 127.0.0.1

	Listening host address for channel proxy


--port <NUMBER>
	Default: 41968

	Listening host port for channel proxy


--test <STRING[,STRING]>
	Default: units

	Comma separated list of subdirectories from which tests should be ran

	Or pass an enpty string to run all tests


## Example

if CICD=1 ./${__NAME__} --test mocks; then
	echo 'Success :-D'
else
	echo 'Failure :-('
fi
EOF

	if ((${#_messages[@]})); then
		printf >&2 '%s\n' "${_messages[@]}"
	fi
}

while (("${#1}")); do
	case "${1}" in
		--host)
			_proxy_host="${2}"
			shift 2
		;;
		--port)
			_proxy_port="${2}"
			shift 2
		;;
		--test)
			_test="${2}"
			shift 2
		;;
		--cicd)
			CICD=1
			shift 1
		;;
		--kill|--kill-proxy)
			_kill_proxy=1
		;;
		--help)
			usage ''
			exit 0
		;;
	esac
done

if ! ((${#_test})); then
	_path_glob="tests/**/*.vader"
elif grep -q -- ',' <<<"${_test}"; then
	_path_glob="tests/{${_test}}/**/*.vader"
else
	_path_glob="tests/${_test}/**/*.vader"
fi

if grep -qE '\<mocks\>' <<<"${_test}"; then
	_proxy_search="$(pgrep --full "${_proxy_exec##*/} (--mock|--port ${_proxy_port}).*(--port ${_proxy_port}|--mock)")"

	if ((${#_proxy_search})); then
		printf >&2 'Proxy with similar arguments already started with PID -> %s\n' "${_proxy_search}"
		_proxy_pid="${_proxy_search}"
	else
		"${_proxy_exec}" "${_proxy_args[@]}" >"${_proxy_log}" 2>&1 &
		# disown
		_proxy_pid="$!"
	fi
	if ! ((_proxy_pid)); then
		printf >&2 'Failed to get PID for proxy!\n'
		exit 1
	else
		printf >&2 'Proxy started with PID %i named %s\n' "${_proxy_pid}" "$(ps -q "${_proxy_pid}" -o comm=,args=)"
	fi
fi

if ((CICD)); then
	vim -Nu <(cat <<VIMRC
	set rtp+=~/.vim/plugged/vader.vim
	set rtp+=.
VIMRC
) -c "silent Vader! ${_path_glob}"
	_tests_exit_status="${?}"
else
	vim -Nu <(cat <<VIMRC
	set rtp+=~/.vim/plugged/vader.vim
	set rtp+=.
VIMRC
) -c "Vader ${_path_glob}"
	_tests_exit_status="${?}"
fi

if ((_kill_proxy)) && grep -qE '\<mocks\>' <<<"${_test}"; then
	if ((${#_proxy_pid})) && [[ "${_proxy_pid}" -gt 1 ]]; then
		printf 'Attempting to kill proxy PID %i process -> %s\n' "${_proxy_pid}" "$(ps -q "${_proxy_pid}" -o comm=,args=)"
		## TODO: figure out why `-SIGINT` works when interactive proxy was started, but
		##       no works when scripted and backgrounded
		# kill -SIGTERM "${_proxy_pid}"
		kill -SIGINT "${_proxy_pid}"
	else
		printf >&2 'Failed to find a PID for proxy\n'
	fi

	printf 'Mocked Proxy Logs\n'
	cat "${_proxy_log}"

	rm "${_proxy_log:?No tmp file to remove}"
fi

exit "${_tests_exit_status}"

