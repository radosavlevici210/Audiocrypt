#!/usr/bin/env python3
import http.server
import socketserver
import os
import mimetypes
import urllib.parse

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=os.getcwd(), **kwargs)
    
    def guess_type(self, path):
        mimetype, encoding = mimetypes.guess_type(path)
        if path.endswith('.mp3'):
            return 'audio/mpeg'
        return mimetype
    
    def do_GET(self):
        # Custom routing for better UX
        parsed_path = urllib.parse.urlparse(self.path)
        path = parsed_path.path
        
        # Serve preview page as default
        if path == '/':
            if os.path.exists('preview.html'):
                self.path = '/preview.html'
            else:
                self.path = '/index.html'
        
        # Handle app route
        elif path == '/app' or path == '/app/':
            self.path = '/index.html'
        
        # Default file serving
        return super().do_GET()
    
    def log_message(self, format, *args):
        # Custom logging with emojis
        message = format % args
        if '200' in message:
            print(f"✅ {message}")
        elif '404' in message:
            print(f"❌ {message}")
        else:
            print(f"ℹ️  {message}")

PORT = 5000
Handler = CustomHTTPRequestHandler

print(f"🌐 Starting Crypto Sound Miner server on port {PORT}")
print(f"🔗 Preview at: http://0.0.0.0:{PORT}/")
print(f"🎵 App at: http://0.0.0.0:{PORT}/app")
print("🚀 Ready to mine crypto with music!")
print("-" * 50)

try:
    with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
        httpd.serve_forever()
except KeyboardInterrupt:
    print("\n🛑 Server stopped by user")
except Exception as e:
    print(f"❌ Server error: {e}")
