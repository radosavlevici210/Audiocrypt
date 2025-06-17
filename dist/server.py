#!/usr/bin/env python3
import http.server
import socketserver
import os
import mimetypes

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=os.getcwd(), **kwargs)
    
    def guess_type(self, path):
        mimetype, encoding = mimetypes.guess_type(path)
        if path.endswith('.mp3'):
            return 'audio/mpeg'
        return mimetype

PORT = 5000
Handler = CustomHTTPRequestHandler

print(f"🌐 Starting Crypto Sound Miner server on port {PORT}")
print(f"🔗 Access your app at: http://0.0.0.0:{PORT}")
print("🎵 Ready to mine crypto with music!")
print("-" * 50)

try:
    with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
        httpd.serve_forever()
except KeyboardInterrupt:
    print("\n🛑 Server stopped by user")
except Exception as e:
    print(f"❌ Server error: {e}")
