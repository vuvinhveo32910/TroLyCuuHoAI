"""Same-origin demo web gateway. The model/admin API remains on loopback."""
import http.client
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import ipaddress
import json
import os
from pathlib import Path
import re
import socket
from urllib.parse import unquote, urlsplit


def local_ipv4_addresses():
    addresses = {'127.0.0.1'}
    try:
        addresses.update(socket.gethostbyname_ex(socket.gethostname())[2])
    except OSError:
        pass
    return sorted(address for address in addresses
                  if ipaddress.ip_address(address).is_private
                  and not ipaddress.ip_address(address).is_unspecified)


class GatewayServer(ThreadingHTTPServer):
    allow_reuse_address = os.name != 'nt'
    daemon_threads = True

    def server_bind(self):
        if os.name == 'nt':
            self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
        super().server_bind()


def make_gateway(web_root, api_port, allowed_hosts):
    root = Path(web_root).resolve()
    hosts = frozenset(allowed_hosts) | {'127.0.0.1', 'localhost'}

    class Handler(SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=str(root), **kwargs)

        def log_message(self, *_):
            pass

        def setup(self):
            super().setup()
            self.connection.settimeout(30)

        def end_headers(self):
            self.send_header('X-Content-Type-Options', 'nosniff')
            self.send_header('Referrer-Policy', 'same-origin')
            self.send_header('Cache-Control', 'no-cache')
            super().end_headers()

        def json_error(self, status, message):
            body = json.dumps({'error': message}, ensure_ascii=False).encode('utf-8')
            self.send_response(status)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            if self.command != 'HEAD':
                self.wfile.write(body)

        def check_request(self):
            try:
                address = ipaddress.ip_address(self.client_address[0])
                authority = urlsplit('http://' + self.headers.get('Host', ''))
                valid = (address.is_private and authority.hostname in hosts
                         and (authority.port or 80) == self.server.server_port
                         and not authority.username and not authority.password
                         and not authority.path and not authority.query and not authority.fragment
                         and len(self.headers.get_all('Host', [])) == 1)
                origin = self.headers.get('Origin')
                if origin:
                    valid = valid and origin == 'http://' + self.headers['Host']
                valid = valid and self.headers.get('Sec-Fetch-Site') != 'cross-site'
                parsed = urlsplit(self.path)
                valid = valid and not parsed.scheme and not parsed.netloc and self.path.startswith('/')
            except ValueError:
                valid = False
            if not valid:
                self.json_error(403, 'Địa chỉ hoặc nguồn kết nối không được phép.')
            return valid

        def api_method(self, path):
            if path in {'/api/chat', '/api/warmup', '/api/analyze-image'}:
                return 'POST'
            if path in {'/api/status', '/api/knowledge'} or re.fullmatch(
                    r'/api/(knowledge/[0-9]+|source/[A-Za-z0-9_.-]+)', path):
                return 'GET'
            return None

        def proxy_api(self):
            path = urlsplit(self.path).path
            expected = self.api_method(path)
            if expected is None:
                self.json_error(403, 'API này chỉ dùng trực tiếp trên máy chủ.')
                return
            if self.command != expected:
                self.json_error(405, 'Phương thức không được hỗ trợ.')
                return
            body = None
            if expected == 'POST':
                if self.headers.get('Transfer-Encoding') or len(self.headers.get_all('Content-Length', [])) != 1:
                    self.json_error(400, 'Yêu cầu cần độ dài nội dung hợp lệ.')
                    return
                try:
                    length = int(self.headers.get('Content-Length', '0'))
                except ValueError:
                    length = 0
                maximum = 14 * 1024 * 1024 if path == '/api/analyze-image' else 65536
                if not 0 < length <= maximum:
                    self.json_error(413, 'Nội dung gửi lên quá lớn hoặc trống.')
                    return
                if self.headers.get('Content-Type', '').split(';')[0].strip().lower() != 'application/json':
                    self.json_error(415, 'Hãy gửi dữ liệu dạng JSON.')
                    return
                body = self.rfile.read(length)
                if len(body) != length:
                    self.json_error(400, 'Nội dung gửi lên chưa đầy đủ.')
                    return
            upstream = http.client.HTTPConnection('127.0.0.1', api_port, timeout=300)
            responded = False
            try:
                # Never relay arbitrary destinations, Origin, cookies or admin headers.
                upstream.request(self.command, self.path, body=body,
                                 headers={'Content-Type': 'application/json; charset=utf-8'} if body else {})
                response = upstream.getresponse()
                self.send_response(response.status)
                for name in ('Content-Type', 'Content-Length', 'Content-Disposition'):
                    value = response.getheader(name)
                    if value is not None:
                        self.send_header(name, value)
                self.end_headers()
                responded = True
                while chunk := response.read(65536):
                    self.wfile.write(chunk)
            except (OSError, http.client.HTTPException):
                if not responded:
                    self.json_error(503, 'Chưa kết nối được dịch vụ AI trên máy chủ.')
            finally:
                upstream.close()

        def serve_static(self):
            decoded = unquote(urlsplit(self.path).path)
            if '\\' in decoded or '\x00' in decoded or '..' in Path(decoded).parts:
                self.json_error(404, 'Không tìm thấy tệp.')
                return
            candidate = (root / decoded.lstrip('/')).resolve()
            if not candidate.is_relative_to(root) or any(part.startswith('.') for part in Path(decoded).parts if part != '/'):
                self.json_error(404, 'Không tìm thấy tệp.')
                return
            if candidate.is_file():
                self.path = urlsplit(self.path).path
            elif decoded == '/' or (not candidate.suffix and not candidate.exists()):
                if not (root / 'index.html').resolve().is_relative_to(root):
                    self.json_error(404, 'Không tìm thấy tệp.')
                    return
                self.path = '/index.html'
            else:
                self.json_error(404, 'Không tìm thấy tệp.')
                return
            if self.command == 'HEAD':
                super().do_HEAD()
            else:
                super().do_GET()

        def do_GET(self):
            if not self.check_request():
                return
            if urlsplit(self.path).path.startswith('/api/'):
                self.proxy_api()
            else:
                self.serve_static()

        def do_HEAD(self):
            if not self.check_request():
                return
            if urlsplit(self.path).path.startswith('/api/'):
                self.json_error(405, 'Phương thức không được hỗ trợ.')
            else:
                self.serve_static()

        def do_POST(self):
            if self.check_request():
                self.proxy_api()

        def do_OPTIONS(self):
            if self.check_request():
                self.json_error(403, 'Mở web từ cùng địa chỉ máy chủ để sử dụng API.')

        def list_directory(self, _):
            self.json_error(404, 'Không tìm thấy tệp.')
            return None

    return Handler
