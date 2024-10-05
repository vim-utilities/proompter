#!/usr/bin/env python


license = """
This project is licensed based on use-case


## Commercial and/or proprietary use

If a project is **either** commercial or (`||`) proprietary, then please
contact the author for pricing and licensing options to make use of code and/or
features from this repository.

---

## Non-commercial and FOSS use

If a project is **both** non-commercial and (`&&`) published with a license
compatible with AGPL-3.0, then it may utilize code from this repository under
the following terms.

```
Proxy traffic between Vim channel requests and Ollama LLM API
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
"""


import http.server
import json
import socketserver
import urllib.request
import requests


def modify_template_file(path, **kwargs):
    try:
        with open(path, 'r') as file_descriptor:
            file_content = file_descriptor.read()
            return file_content.format(**kwargs)
    except FileNotFoundError:
        print(f"Cannot read file at: {file_path}")
        return None


class ChannelProxy(http.server.SimpleHTTPRequestHandler):
    """
    Proxy connections from Vim `ch_sendraw` channel to API defined in HTTP request path
    """
    def do_POST(self):
        """
        Parse request body as JSON for '{"stream": true}' to determine if response should be buffered by result or retuned line-by-line

        In either case the HTTP path (`self.path`) is treated as the target for proxying requests

        ## Expects client HTTP requests similar to

        ```
        POST http://127.0.0.1:11434/api/generate HTTP/1.1
        Host: 127.0.0.1:11435
        Content-Type: application/json
        Content-Length: 104

        {"prompt":"In one sentence tell me why Vim is the best.","model":"codellama","stream":true,"raw":false}
        ```

        > Note; above HTTP request should **not** be copy/paste-ed because lines must be separated by carriage-return and new-line characters (`\\r\\n`)
        """
        content_length = int(self.headers['Content-Length'])
        if content_length <= 0:
            self.send_error(400, 'Bad Request', 'Request missing body data')

        post_data = self.rfile.read(content_length)
        json_data = json.loads(post_data)
        print('post_data ->', post_data)
        if json_data['stream'] is True:
            return self._POST_Response_StreamLines(post_data)
        elif json_data['stream'] is False:
            return self._POST_Response_Complete(post_data)
        elif json_data['stream'] is not True:
            self.send_error(400, 'Bad Request', 'Body data "stream" is neither true or false')

    def _POST_Response_StreamLines(self, post_data):
        """
        Reply to client with response lines (up-to 1024 bytes in length) as fast as API will provide

        > Note; it is up to client to figure-out when connection is done and/or can be safely closed

        ## Attributions

        - https://stackoverflow.com/questions/17822342/understanding-python-http-streaming
        """
        print(f"Sending request to {self.path} with data ->", post_data)
        response = requests.post(self.path, data=post_data, headers=self.headers, stream=True)
        if response.status_code == 200:
            print("Streaming", response)
            for line in response.iter_lines():
                print(line)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.send_response(response.status_code)
                self.wfile.write(line)
        else:
            # print("Error", response.status_code, response.reason)
            self.send_error(response.status_code, response.reason)
            return


    def _POST_Response_Complete(self, post_data):
        """
        Wait for full response from API server before replying to client
        """
        request = urllib.request.Request(
            self.path,
            data=post_data,
            headers={
                'Content-Type': self.headers['Content-Type'],
                'Content-Length': str(len(post_data)),
            },
            method='POST',
        )

        try:
            with urllib.request.urlopen(request) as response:
                response_data = response.read()
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.send_response(response.getcode())
                self.wfile.write(response_data)
        except urllib.error.HTTPError as error:
            error_message = error.read().decode()
            print("HTTP Error:", error.code, error_message)
            self.send_error(error.code, error_message, 'API no wants to talk to you like that?!')
        except urllib.error.URLError as error:
            print("URL Error:", str(error))
            self.send_error(502, 'Bad Gateway: unable to reach the API')
        except Exception as error:
            print('Unexpected error:', str(error))
            self.send_error(500, 'Internal Server Error')


if __name__ == '__main__':
    import argparse
    import os
    import textwrap

    HOST = '127.0.0.1'
    PORT = 11435

    parser = argparse.ArgumentParser(
        prog='Proompter Channel Proxy',
        formatter_class=argparse.RawTextHelpFormatter,
        description='Proxy traffic from Vim `ch_sendraw` calls to Ollama API',
        allow_abbrev=False
    )

    ## Script related arguments
    parser.add_argument('--version', action='version', version='%(prog)s 0.0.1')
    parser.add_argument('--verbose', action='store_true', help='Print info to standard out (STDOUT) during execution')

    ## Server related arguments
    parser.add_argument('--host', default=HOST, help='Listening address for %(prog)s (default: %(default)s)', type=str)
    parser.add_argument('--port', default=PORT, help='Listening port for %(prog)s (default: %(default)s)', type=int)

    ## SystemD related arguments
    parser.add_argument('--clobber', type=bool, help='Allow overwriting preexisting install script')
    parser.add_argument('--install-systemd', type=str, help=textwrap.dedent('''\
        %(prog)s install SystemD path

        Tip, list SystemD unit paths via:

            systemd-analyze unit-paths
            systemd-analyze --user unit-paths

        ...  For services not maintained by a package-manager using a path with "local" sub-directory may be wise.

        Example:

            python {script} --install-systemd $HOME/.local/share/systemd/user/proompter-channel-proxy.service
    '''.format(script=argparse._sys.argv[0])))

    args = parser.parse_args()

    if args.install_systemd:
        if os.path.exists(args.install_systemd) and args.clobber is not True:
            raise ValueError(f"--install-systemd {args.install_systemd} already exists, try adding '--clobber'")

        install_systemd_directory = os.path.dirname(args.install_systemd)
        if os.path.exists(install_systemd_directory) is not True:
            os.makedirs(install_systemd_directory)
            if args.verbose:
                print(f"Created SystemD directory at: {install_systemd_directory}")

        project_directory = os.path.dirname(os.path.dirname(__file__))
        template_systemd_path = os.path.join(project_directory, 'systemd', 'template_proompter-channel-proxy.service')
        if os.path.exists(template_systemd_path) is not True:
            raise ValueError(f"Cannot find SystemD template at: {template_systemd_path}")

        template_systemd_result = modify_template_file(
            template_systemd_path,
            script_path=__file__,
        )

        with open(args.install_systemd, 'x') as install_systemd_file_descriptor:
            install_systemd_file_descriptor.write(template_systemd_result)
            if args.verbose:
                print(f"SystemD file written to: {args.install_systemd}")
    else:
        with socketserver.TCPServer((args.host, args.port), ChannelProxy) as httpd:
            if args.verbose:
                print(f"Serving at port: {args.host}:{args.port}")

            httpd.serve_forever()

