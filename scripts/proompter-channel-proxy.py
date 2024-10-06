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
import urllib.parse
import requests
import base64
import sys


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

    verbose = False

    def init(self, *args, verbose=False, **kwargs):
        """
        Add verbose option
        """
        self.verbose = verbose

        super().__init__(*args, **kwargs)

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

        if json_data['stream'] is True:
            return self._POST_Response_StreamLines(post_data)
        elif json_data['stream'] is False:
            return self._POST_Response_Complete(post_data)
        elif json_data['stream'] is not True:
            return self.send_error(400, 'Bad Request', 'Body data "stream" is neither true or false')

    def _POST_Response_StreamLines(self, post_data):
        """
        Reply to client with response lines (up-to 1024 bytes in length) as fast as API will provide

        > Note; it is up to client to figure-out when connection is done and/or can be safely closed

        ## Attributions

        - https://stackoverflow.com/questions/17822342/understanding-python-http-streaming
        """
        if self.verbose:
            print(f"Sending request to {self.path} with data ->", post_data)

        response = requests.post(self.path, data=post_data, headers=self.headers, stream=True)
        if response.status_code == 200:
            if self.verbose:
                print("Streaming response ->", response)

            for line in response.iter_lines():
                if self.verbose:
                    print("  line ->", line)
                self.send_response(response.status_code)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(line)
        else:
            if self.verbose:
                print("Error", response.status_code, response.reason)
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
                if self.verbose:
                    print("Retuning response_data ->", response_data)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.send_response(response.getcode())
                self.wfile.write(response_data)
        except urllib.error.HTTPError as error:
            error_message = error.read().decode()
            if self.verbose:
                print("HTTP Error:", error.code, error_message)
            self.send_error(error.code, error_message, 'API no wants to talk to you like that?!')
        except urllib.error.URLError as error:
            if self.verbose:
                print("URL Error:", str(error))
            self.send_error(502, 'Bad Gateway: unable to reach the API')
        except Exception as error:
            if self.verbose:
                print('Unexpected error:', str(error))
            self.send_error(500, 'Internal Server Error')


class HTTPResponseSocket_Mock:
    """
    Similar to `autoload/proompter/parse.vim` -> `proompter#parse#JSONLinesFromHTTPResponse`
    We gotta slice and dice

    ## See

    - `http.client` -> `HTTPResponse.begin`
    - `http.client` -> `_read_headers`
    """

    def __init__(self, data):
        """
        Re-encodes string `data` if necessary
        """
        if isinstance(data, str):
            data = data.encode('utf-8')

        self.data = data
        self.slice_start = 0

    def readline(self, bufsize=-1):
        """
        Read `bufsize` from `self.data` when seeking for CRLF (`\\r\\n`)

        When `bufsize` is undefined, or less than zero, then read up-to last
        byte when seeking CRLF characters.
        """
        separator = b'\r\n'

        if bufsize <= -1:
            bufsize = len(self.data) - self.slice_start

        slice_offset = self.data.find(separator, self.slice_start, bufsize)
        if slice_offset == -1:
            slice_offset = len(self.data)
        elif slice_offset == 0:
            slice_offset += 2

        line = self.data[self.slice_start:slice_offset]
        self.slice_start += len(line)
        if self.slice_start < len(self.data):
            self.slice_start += 2
            ## NOTE: re-adding the `separator` allows inherited parsers to
            ## parse headers correctly X-D
            line += separator

        return line

    def read(self, bufsize=-1):
        """
        Repeatably call `self.readline` to return `bufsize` number of bytes
        """
        lines = b''
        while self.slice_start < len(self.data):
            line = self.readline(bufsize)
            lines += line
            if self.slice_start < len(self.data):
                lines += b'\r\n'

        return lines

    def makefile(self, mode, buffering=-1):
        return self

    def close(self):
        self.data = b''
        self.slice_start = 0


class ChannelProxy_Mock(ChannelProxy):
    """
    Attributions:

    - https://parsiya.net/blog/2020-11-15-customizing-pythons-simplehttpserver/
    """
    def _POST_Response_StreamLines(self, post_data):
        print('ChannelProxy_Mock._POST_Response_StreamLines post_data ->', post_data)
        print('  self.path ->', self.path)

        parsed_url = urllib.parse.urlparse(self.path)
        if len(parsed_url.query) <= 0:
            print('  parsed_url ->', parsed_url)
            return self.send_error(400, 'Bad Request: missing mock query string', 'Needs "?response=<base64-encoded-string>"')

        query_string = urllib.parse.parse_qs(parsed_url.query)
        response_base64 = query_string.get('response')
        if response_base64 is None:
            print('  query_string ->', query_string)
            print('  response_base64 ->', response_base64)
            return self.send_error(400, 'Bad Request: missing mock query string -> "?response=<base64-encoded-string>"', 'Needs "<base64-encoded-string>"')

        response_string = ''
        for item in response_base64:
            response_string += base64.b64decode(response_base64[0]).decode('utf-8')
        # print('  response_string ->', response_string)

        if len(response_string) <= 0:
            print('  response_string ->', response_string)
            return self.send_error(400, 'Bad Request: missing mock query string -> "?response=<base64-encoded-string>"', 'Needs "<base64-encoded-string>"')

        response_socket = HTTPResponseSocket_Mock(response_string)
        mock_response = http.client.HTTPResponse(response_socket)
        # mock_response = http.client.HTTPResponse(response_socket, debuglevel=42069)

        ## Attempt to pare-out headers before reading lines of response body
        mock_response.begin()
        while True:
            line = mock_response.readline()
            if len(line) <= 0:
                break

            self.send_response(mock_response.code)
            print('  mock_response.code ->', mock_response.code)
            for header in mock_response.getheaders():
                print('  header ->', header)
                self.send_header(*header)

            if len(mock_response.headers):
                self.end_headers()

            print('  line ->', line)
            self.wfile.write(line)

    def _POST_Response_Complete(self, post_data):
        print('ChannelProxy_Mock._POST_Response_Complete post_data ->', post_data)
        print('  self.path ->', self.path)
        parsed_url = urllib.parse.urlparse(self.path)
        if len(parsed_url.query) <= 0:
            print('  parsed_url ->', parsed_url)
            return self.send_error(400, 'Bad Request: missing mock query string', 'Needs "?response=<base64-encoded-string>"')

        query_string = urllib.parse.parse_qs(parsed_url.query)
        response_base64 = query_string.get('response')
        if response_base64 is None:
            print('  query_string ->', query_string)
            print('  response_base64 ->', response_base64)
            return self.send_error(400, 'Bad Request: missing mock query string -> "?response=<base64-encoded-string>"', 'Needs "<base64-encoded-string>"')

        response_string = ''
        for item in response_base64:
            response_string += base64.b64decode(response_base64[0]).decode('utf-8')
        # print('  response_string ->', response_string)

        if len(response_string) <= 0:
            print('  response_string ->', response_string)
            return self.send_error(400, 'Bad Request: missing mock query string -> "?response=<base64-encoded-string>"', 'Needs "<base64-encoded-string>"')

        response_socket = HTTPResponseSocket_Mock(response_string)
        mock_response = http.client.HTTPResponse(response_socket)
        ## Attempt to pare-out headers before reading lines of response body
        mock_response.begin()
        self.send_response(mock_response.code)
        body = mock_response.read()
        for header in mock_response.getheaders():
            print('  header ->', header)
            self.send_header(*header)

        if len(mock_response.headers):
            self.end_headers()

        print('  body ->', body)
        self.wfile.write(body)


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

    parser.add_argument('--mock', action='store_true', help='Used for unit testing Vim channel stuff')

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
            raise ValueError(f"Cannot find SystemD template at -> {template_systemd_path}")

        template_systemd_result = modify_template_file(
            template_systemd_path,
            script_path=__file__,
        )

        with open(args.install_systemd, 'x') as install_systemd_file_descriptor:
            install_systemd_file_descriptor.write(template_systemd_result)
            if args.verbose:
                print(f"SystemD file written to -> {args.install_systemd}")

    elif args.mock is True:
        with socketserver.TCPServer((args.host, args.port), ChannelProxy_Mock) as httpd:
            if args.verbose:
                print(f"Mocking API at -> {args.host}:{args.port}")

            try:
                httpd.serve_forever()
            except KeyboardInterrupt:
                print('Shutting down server')
                httpd.shutdown()
                sys.exit(0)

    elif args.mock is False:
        with socketserver.TCPServer((args.host, args.port), ChannelProxy) as httpd:
            if args.verbose:
                print(f"Serving proxy at -> {args.host}:{args.port}")

            try:
                httpd.serve_forever()
            except KeyboardInterrupt:
                print('Shutting down server')
                httpd.shutdown()
                sys.exit(0)

    else:
        raise ValueError('Wut did --mock get set to?!')

