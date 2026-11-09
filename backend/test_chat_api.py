import json
from pathlib import Path
import sys
import threading
import unittest
from urllib.error import HTTPError
from urllib.request import Request, urlopen

sys.path.insert(0, str(Path(__file__).parent / 'medgemma'))
from server import ChatService, ThreadingHTTPServer, make_handler


class Runner:
    state, error, load_seconds = 'ready', '', 0
    def answer(self, *args):
        return {'answer': 'Câu trả lời thử', 'truncated': False, 'generated_tokens': 3}
    def warmup(self):
        return False


class ApiTests(unittest.TestCase):
    def setUp(self):
        self.service = ChatService(runner=Runner(), sqlite_path=None, preload_enabled=False)
        self.server = ThreadingHTTPServer(('127.0.0.1', 0), make_handler(
            self.service, allowed_origins=['https://web.example'], allow_local_web=True))
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.url = f'http://127.0.0.1:{self.server.server_port}'

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()

    def request(self, path, method='GET', origin='http://localhost:63788', data=None, headers=None):
        values = {'Origin': origin, **(headers or {})}
        if data is not None:
            values['Content-Type'] = 'application/json'
        req = Request(self.url + path, method=method, headers=values,
                      data=json.dumps(data).encode() if data is not None else None)
        try:
            return urlopen(req, timeout=5)
        except HTTPError as error:
            return error

    def test_local_flutter_chat_and_utf8(self):
        with self.request('/api/chat', 'POST', data={'message': 'tôi bị đau đầu'}) as r:
            self.assertEqual(r.status, 200)
            self.assertEqual(r.headers['Access-Control-Allow-Origin'], 'http://localhost:63788')
            self.assertEqual(json.load(r)['answer'], 'Câu trả lời thử')

    def test_preflight_json(self):
        with self.request('/api/chat', 'OPTIONS', headers={
            'Access-Control-Request-Method': 'POST', 'Access-Control-Request-Headers': 'content-type'}) as r:
            self.assertEqual(r.status, 204)
            self.assertIsNone(r.headers.get('Access-Control-Allow-Credentials'))

    def test_external_unknown_origin_rejected(self):
        with self.request('/api/chat', 'POST', origin='https://evil.example', data={'message': 'a'}) as r:
            self.assertEqual(r.status, 403)
            self.assertIsNone(r.headers.get('Access-Control-Allow-Origin'))

    def test_admin_not_exposed_to_flutter_even_with_token(self):
        for path, method in [('/api/admin/meta', 'GET'), ('/api/admin/entries', 'GET')]:
            with self.request(path, method) as r:
                self.assertEqual(r.status, 403)
                self.assertIsNone(r.headers.get('Access-Control-Allow-Origin'))

    def test_admin_preflight_rejected(self):
        with self.request('/api/admin/entries/1/save', 'OPTIONS', headers={
            'Access-Control-Request-Method': 'POST', 'Access-Control-Request-Headers': 'content-type,x-admin-token'}) as r:
            self.assertEqual(r.status, 403)

    def test_explicit_https_origin(self):
        with self.request('/api/status', origin='https://web.example') as r:
            self.assertEqual(r.status, 200)
            self.assertEqual(json.load(r)['approved_entries'], 0)

    def test_loopback_lookalike_and_null_rejected(self):
        for origin in ['null', 'http://localhost.evil.example:8080', 'http://127.0.0.1:8080/bad']:
            with self.request('/api/status', origin=origin) as r:
                self.assertEqual(r.status, 403)


if __name__ == '__main__':
    unittest.main()
