# Proompter
[heading__top]:
  #proompter
  "&#x2B06; Leverage local LLM via Vim to boost bug breading within your code"


Leverage local LLM via Vim to boost bug breading within your code

## [![Byte size of Proompter][badge__main__proompter__source_code]][proompter__main__source_code] [![Open Issues][badge__issues__proompter]][issues__proompter] [![Open Pull Requests][badge__pull_requests__proompter]][pull_requests__proompter] [![Latest commits][badge__commits__proompter__main]][commits__proompter__main][![GitHub Actions Build Status][badge__github_actions]][activity_log__github_actions][![License][badge__license]][branch__current__license]


---


- [:arrow_up: Top of Document][heading__top]
- [:building_construction: Requirements][heading__requirements]
- [:zap: Quick Start][heading__quick_start]
  - [List available user paths for SystemD services][heading__list_available_user_paths_for_systemd_services]
  - [Install with Vim package manager of choice][heading__install_with_vim_package_manager_of_choice]
  - [Ensure the Ollama service is running][heading__ensure_the_ollama_service_is_running]
  - [Ensure the Vim channel proxy is running][heading__ensure_the_vim_channel_proxy_is_running]
- [&#x1F9F0; Usage][heading__usage]
  - [Author or select a callback][heading__author_or_select_a_callback]
  - [Configure Proompter][heading__configure_proompter]
- [&#x1F5D2; Notes][heading__notes]
- [:chart_with_upwards_trend: Contributing][heading__contributing]
  - [:trident: Forking][heading__forking]
  - [:currency_exchange: Sponsor][heading__sponsor]
- [:card_index: Attribution][heading__attribution]
- [:balance_scale: Licensing][heading__license]
  - [Commercial and/or proprietary use][heading__commercial_andor_proprietary_use]
  - [Non-commercial and FOSS use][heading__noncommercial_and_foss_use]


---



## Requirements
[heading__requirements]:
  #requirements
  "&#x1F3D7; Prerequisites and/or dependencies that this project needs to function properly"


This repository requires the [Vim][vim__home] text editor to be installed the
source code is available on [GitHub -- `vim/vim`][vim__github], and most GNU
Linux package managers are able to install Vim directly, eg...


- Arch based Operating Systems
   ```bash
   sudo packman -Syy
   sudo packman -S vim
   ```
- Debian derived Distributions
   ```bash
   sudo apt-get update
   sudo apt-get install vim
   ```

...  Additionally for local LLM interactions this plugin expects
[ollama](https://github.com/ollama/ollama) to be installed and running, as well
as [Python](https://www.python.org/) run-time to facilitate
`scripts/proompter-channel-proxy.py` service.


______


## Quick Start
[heading__quick_start]:
  #quick-start
  "&#9889; Perhaps as easy as one, 2.0,..."


### List available user paths for SystemD services
[heading__list_available_user_paths_for_systemd_services]: #list-available-user-paths-for-systemd-services

```bash
systemd-analyze --user unit-paths | grep $HOME
```

**Example output**

```
~/.config/systemd/user.control
~/.config/systemd/user
~/.config/kdedefaults/systemd/user
~/.local/share/systemd/user
```

### Install with Vim package manager of choice
[heading__install_with_vim_package_manager_of_choice]: #install-with-vim-package-manager-of-choice

```vim
Plug 'vim-utilities/proompter' {
     \   'do': 'scripts/proompter-channel-proxy.py --install-systemd "' . $HOME . '/.local/share/systemd/user/proompter-channel-proxy.service"'
     \ }
```

> Note: if installing manually, such as cloning via Git, then you may invoke
> the proxy installation directly;
>
> `scripts/proompter-channel-proxy.py --install-systemd "$HOME/.local/share/systemd/user/proompter-channel-proxy.service"`
>
> Dev tip: if modifying the installed SystemD configuration you may pop
> warnings, about changes detected on disk here's how to fix that;
>
> `systemctl --user daemon-reload`

---

### Ensure the Ollama service is running
[heading__ensure_the_ollama_service_is_running]: #ensure-the-ollama-service-is-running

```bash
systemctl is-active --quiet ollama.service || {
  sudo systemctl restart ollama.service
}
```

---

### Ensure the Vim channel proxy is running
[heading__ensure_the_vim_channel_proxy_is_running]: #ensure-the-vim-channel-proxy-is-running

```bash
systemctl --user is-active --quiet proompter-channel-proxy.service || {
  systemctl --user proompter-channel-proxy.service
}
```

______


## Usage
[heading__usage]:
  #usage
  "&#x1F9F0; How to utilize this repository"


Currently no Motions or Commands are provided, and such customization is an
exercise for each entity using this plugin.  Instead there are a kit of helper
functions for creating your own Vim/LLM integration experience!

---

### Author or select a callback
[heading__author_or_select_a_callback]: #author-or-select-a-callback

> Tip: find examples within;
>
> -  `autoload/proompter/callback/channel.vim`
> -  `autoload/proompter/callback/prompt.vim`

```vim
function! MyProompterLineStreamCallback(channel_response, api_response, ...) abort
  let l:http_response = proompter#parse#HTTPResponse(a:api_response)
  for l:http_body_data in l:http_response.body
    let l:api_data = proompter#parse#MessageOrResponseFromAPI(l:http_body_data)
    echoe 'l:api_data ->' l:api_data
  endfor
endfunction
```

---

### Configure Proompter
[heading__configure_proompter]: #configure-proompter

```vim
let g:proompter = {
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
      \       'callback': function('MyProompterLineStreamCallback'),
      \     },
      \   },
      \   'models': {
      \     'codellama': {
      \       'data': {
      \         'prompt': '<<SYS>>Pretend you are a senior software engineer<</SYS>>',
      \         'raw': v:false,
      \         'stream': v:true,
      \       },
      \     },
      \   },
      \ }
```

> Tip: check `:help proompter-configuration` for some more advanced example(s)


______


## Notes
[heading__notes]:
  #notes
  "&#x1F5D2; Additional things to keep in mind when developing"


This repository may not be feature complete and/or fully functional, Pull
Requests that add features or fix bugs are certainly welcomed.

> Tip: check the `CHANGELOG.md` for features and/or bugs that may want
> attentions of those so inclined.

Most of the code and documentation, at least up to tagged version `0.0.1`, is
authored by a human.  LLMs were no help with Vim script.


______


## Contributing
[heading__contributing]:
  #contributing
  "&#x1F4C8; Options for contributing to proompter and vim-utilities"


Options for contributing to Proompter and Vim Utilities


---


### Forking
[heading__forking]:
  #forking
  "&#x1F531; Tips for forking proompter"


Start making a [Fork][proompter__fork_it] of this repository to an account that
you have write permissions for.


- Add remote for fork URL. The URL syntax is
  _`git@github.com:<NAME>/<REPO>.git`_...


```bash
cd ~/git/hub/vim-utilities/proompter

git remote add fork git@github.com:<NAME>/proompter.git
```

- Adjust your package manager configuration
   ```vim
   Plug '~/git/hub/vim-utilities/proompter' { 'do': '' }
   ```

- Commit your changes and push to your fork, eg. to fix an issue...

```bash
cd ~/git/hub/vim-utilities/proompter


git commit -F- <<'EOF'
:bug: Fixes #42 Issue


**Edits**


- `<SCRIPT-NAME>` script, fixes some bug reported in issue
EOF


git push fork main
```

> Note, the `-u` option may be used to set `fork` as the default remote, eg.
> _`git push -u fork main`_ however, this will also default the `fork` remote
> for pulling from too! Meaning that pulling updates from `origin` must be done
> explicitly, eg. _`git pull origin main`_

- Then on GitHub submit a Pull Request through the Web-UI, the URL syntax is
  _`https://github.com/<NAME>/<REPO>/pull/new/<BRANCH>`_


> Note; to decrease the chances of your Pull Request needing modifications
> before being accepted, please check the
> [dot-github](https://github.com/vim-utilities/.github) repository for
> detailed contributing guidelines.


---


### Sponsor
  [heading__sponsor]:
  #sponsor
  "&#x1F4B1; Methods for financially supporting vim-utilities that maintains proompter"


Thanks for even considering it!


Via Liberapay you may
<sub>[![sponsor__shields_io__liberapay]][sponsor__link__liberapay]</sub> on a
repeating basis.


Regardless of if you're able to financially support projects such as proompter
that vim-utilities maintains, please consider sharing projects that are useful
with others, because one of the goals of maintaining Open Source repositories
is to provide value to the community.


______


## Attribution
[heading__attribution]:
  #attribution
  "&#x1F4C7; Resources that where helpful in building this project so far."


- [GitHub -- `github-utilities/make-readme`](https://github.com/github-utilities/make-readme)
- [Stack Overflow -- Understanding Python HTTP streaming](https://stackoverflow.com/questions/17822342/understanding-python-http-streaming)


______


## License
[heading__license]:
  #license
  "&#x2696; Legal side of Open Source"

This project is licensed based on use-case

### Commercial and/or proprietary use
[heading__commercial_andor_proprietary_use]: #commercial-andor-proprietary-use

If a project is **either** commercial or (`||`) proprietary, then please
contact the author for pricing and licensing options to make use of code and/or
features from this repository.

---

### Non-commercial and FOSS use
[heading__noncommercial_and_foss_use]: #noncommercial-and-foss-use

If a project is **both** non-commercial and (`&&`) published with a license
compatible with AGPL-3.0, then it may utilize code from this repository under
the following terms.

```
Leverage local LLM via Vim to boost bug breading within your code
Copyright (C) 2024 S0AndS0

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, version 3 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
```


For further details review full length version of
[AGPL-3.0][branch__current__license] License.



[branch__current__license]:
  /LICENSE
  "&#x2696; Full length version of AGPL-3.0 License"

[badge__license]:
  https://img.shields.io/github/license/vim-utilities/proompter

[badge__commits__proompter__main]:
  https://img.shields.io/github/last-commit/vim-utilities/proompter/main.svg

[commits__proompter__main]:
  https://github.com/vim-utilities/proompter/commits/main
  "&#x1F4DD; History of changes on this branch"

[proompter__community]:
  https://github.com/vim-utilities/proompter/community
  "&#x1F331; Dedicated to functioning code"

[issues__proompter]:
  https://github.com/vim-utilities/proompter/issues
  "&#x2622; Search for and _bump_ existing issues or open new issues for project maintainer to address."

[proompter__fork_it]:
  https://github.com/vim-utilities/proompter/fork
  "&#x1F531; Fork it!"

[pull_requests__proompter]:
  https://github.com/vim-utilities/proompter/pulls
  "&#x1F3D7; Pull Request friendly, though please check the Community guidelines"

[proompter__main__source_code]:
  https://github.com/vim-utilities/proompter/
  "&#x2328; Project source!"

[badge__issues__proompter]:
  https://img.shields.io/github/issues/vim-utilities/proompter.svg

[badge__pull_requests__proompter]:
  https://img.shields.io/github/issues-pr/vim-utilities/proompter.svg

[badge__main__proompter__source_code]:
  https://img.shields.io/github/repo-size/vim-utilities/proompter

[vim__home]:
  https://www.vim.org
  "Home page for the Vim text editor"

[vim__github]:
  https://github.com/vim/vim
  "Source code for Vim on GitHub"

[sponsor__shields_io__liberapay]:
  https://img.shields.io/static/v1?logo=liberapay&label=Sponsor&message=vim-utilities

[sponsor__link__liberapay]:
  https://liberapay.com/vim-utilities
  "&#x1F4B1; Sponsor developments and projects that vim-utilities maintains via Liberapay"


[badge__github_actions]:
  https://github.com/vim-utilities/proompter/actions/workflows/test.yaml/badge.svg?branch=main

[activity_log__github_actions]:
  https://github.com/vim-utilities/proompter/actions/workflows/test.yaml

