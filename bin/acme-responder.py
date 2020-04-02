#!/usr/bin/env python3

import ssl
import socketserver
import threading
import re
import os

ALPNDIR="/etc/letsencrypt/alpn-certs"
PROXY_PROTOCOL=False

FALLBACK_KEY="/etc/nginx/ssl/acme/default.key"
FALLBACK_CERTIFICATE="/etc/nginx/ssl/acme/default.pem"

class ThreadedTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    pass

class ThreadedTCPRequestHandler(socketserver.BaseRequestHandler):
    def create_context(self, certfile, keyfile, first=False):
        ssl_context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
        ssl_context.set_ciphers('ECDHE+AESGCM')
        ssl_context.set_alpn_protocols(["acme-tls/1"])
        ssl_context.options |= ssl.OP_NO_TLSv1 | ssl.OP_NO_TLSv1_1
        if first:
            ssl_context.set_servername_callback(self.load_certificate)
        ssl_context.load_cert_chain(certfile=certfile, keyfile=keyfile)
        return ssl_context

    def load_certificate(self, sslsocket, sni_name, sslcontext):
        print("Got request for %s" % sni_name)
        if not re.match(r'^(([a-zA-Z]{1})|([a-zA-Z]{1}[a-zA-Z]{1})|([a-zA-Z]{1}[0-9]{1})|([0-9]{1}[a-zA-Z]{1})|([a-zA-Z0-9][-_.a-zA-Z0-9]{0,61}[a-zA-Z0-9]))\.([a-zA-Z]{2,13}|[a-zA-Z0-9-]{2,30}.[a-zA-Z]{2,3})$', sni_name):
            return

        certfile = os.path.join(ALPNDIR, "%s.crt.pem" % sni_name)
        keyfile = os.path.join(ALPNDIR, "%s.key.pem" % sni_name)

        if not os.path.exists(certfile) or not os.path.exists(keyfile):
            return

        sslsocket.context = self.create_context(certfile, keyfile)

    def handle(self):
        if PROXY_PROTOCOL:
            buf = b""
            while b"\r\n" not in buf:
                buf += self.request.recv(1)

        ssl_context = self.create_context(FALLBACK_CERTIFICATE, FALLBACK_KEY, True)
        newsock = ssl_context.wrap_socket(self.request, server_side=True)

if __name__ == "__main__":
    HOST, PORT = "0.0.0.0", 10443

    server = ThreadedTCPServer((HOST, PORT), ThreadedTCPRequestHandler, bind_and_activate=False)
    server.allow_reuse_address = True
    try:
        server.server_bind()
        server.server_activate()
        server.serve_forever()
    except:
        server.shutdown()