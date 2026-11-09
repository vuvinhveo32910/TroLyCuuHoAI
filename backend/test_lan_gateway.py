import http.client
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import tempfile
import threading
import unittest

from lan_gateway import GatewayServer, make_gateway


class Upstream(BaseHTTPRequestHandler):
    seen = []

    def log_message(self, *_):
        pass

    def do_GET(self):
        body = b'%PDF-test-source' if self.path == '/api/source/example' else b'{"model_state":"ready"}'
        self.send_response(200)
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Content-Type', 'application/pdf' if body.startswith(b'%PDF') else 'application/json')
        self.end_headers()
        self.wfile.write(body)

    def do_POST(self):
        body = self.rfile.read(int(self.headers['Content-Length']))
        self.seen.append((self.path, dict(self.headers), json.loads(body)))
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)


class GatewayTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name) / 'web'
        self.root.mkdir()
        (self.root / 'index.html').write_text('<html>built app</html>', encoding='utf-8')
        (self.root / 'main.dart.js').write_bytes(b'// compiled app')
        (Path(self.temp.name) / 'private.txt').write_text('secret', encoding='utf-8')
        self.upstream = ThreadingHTTPServer(('127.0.0.1', 0), Upstream)
        Upstream.seen = []
        self.gateway = GatewayServer(('127.0.0.1', 0), make_gateway(self.root, self.upstream.server_port, {'192.168.1.42'}))
        self.threads = []
        for server in (self.upstream, self.gateway):
            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()
            self.threads.append(thread)
        self.authority = f'192.168.1.42:{self.gateway.server_port}'

    def tearDown(self):
        for server in (self.gateway, self.upstream):
            server.shutdown()
            server.server_close()
        for thread in self.threads:
            thread.join()
        self.temp.cleanup()

    def request(self, method, path, body=None, headers=None):
        connection = http.client.HTTPConnection('127.0.0.1', self.gateway.server_port, timeout=5)
        values = {'Host': self.authority, **(headers or {})}
        if body is not None:
            values.setdefault('Content-Type', 'application/json')
        connection.request(method, path, body=body, headers=values)
        response = connection.getresponse()
        result = response.status, dict(response.headers), response.read()
        connection.close()
        return result

    def test_lan_web_and_same_origin_api(self):
        self.assertEqual(self.request('GET', '/')[2], b'<html>built app</html>')
        self.assertEqual(self.request('GET', '/main.dart.js')[2], b'// compiled app')
        status, headers, body = self.request('GET', '/api/status')
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body)['model_state'], 'ready')
        self.assertNotIn('Access-Control-Allow-Origin', headers)

    def test_chat_forwards_utf8_without_client_admin_headers(self):
        body = json.dumps({'message': 'Tôi bị trầy tay'}, ensure_ascii=False).encode()
        status, _, result = self.request('POST', '/api/chat', body, {'Origin': 'http://' + self.authority, 'X-Admin-Token': 'should-not-pass'})
        self.assertEqual(status, 200)
        self.assertEqual(result, body)
        _, headers, decoded = Upstream.seen[-1]
        self.assertEqual(decoded['message'], 'Tôi bị trầy tay')
        self.assertEqual(headers['Host'], f'127.0.0.1:{self.upstream.server_port}')
        self.assertNotIn('Origin', headers)
        self.assertNotIn('X-Admin-Token', headers)

    def test_pdf_and_flutter_direct_routes(self):
        status, headers, body = self.request('GET', '/api/source/example')
        self.assertEqual((status, headers['Content-Type'], body), (200, 'application/pdf', b'%PDF-test-source'))
        self.assertEqual(self.request('GET', '/admin')[2], b'<html>built app</html>')

    def test_admin_and_unknown_api_are_not_proxied_or_spa(self):
        for path in ('/api/admin/meta', '/api/admin/entries/1/save', '/api/missing'):
            self.assertEqual(self.request('GET', path)[0], 403)
        self.assertEqual(Upstream.seen, [])

    def test_cross_origin_and_rebinding_host_rejected(self):
        for headers in ({'Origin': 'https://unrelated.example'}, {'Origin': 'null'}, {'Sec-Fetch-Site': 'cross-site'}, {'Host': 'unrelated.example:' + str(self.gateway.server_port)}):
            self.assertEqual(self.request('GET', '/api/status', headers=headers)[0], 403)

    def test_traversal_and_unbuilt_files_not_served(self):
        for path in ('/../private.txt', '/%2e%2e/private.txt', '/.env.local', '/backend/run_chat.py', '/medgemma-1.5-4b-it/model.safetensors'):
            self.assertEqual(self.request('GET', path)[0], 404)

    def test_api_methods_and_content_limits(self):
        self.assertEqual(self.request('GET', '/api/chat')[0], 405)
        self.assertEqual(self.request('POST', '/api/chat', b'{}', {'Content-Type': 'text/plain'})[0], 415)
        self.assertEqual(self.request('POST', '/api/chat', b' ', {'Content-Length': '65537'})[0], 413)
        self.assertEqual(self.request('OPTIONS', '/api/chat')[0], 403)

    def test_unavailable_upstream_is_clear_error(self):
        self.upstream.shutdown()
        self.upstream.server_close()
        self.assertEqual(self.request('GET', '/api/status')[0], 503)


if __name__ == '__main__':
    unittest.main()
