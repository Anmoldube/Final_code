#!/usr/bin/env python3
"""
Simple HTTP server for serving Flutter web app on LAN
"""
import http.server
import socketserver
import os
import socket
import sys
from pathlib import Path

# Configuration
PORT = 3000
DIRECTORY = "build/web"

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    
    def end_headers(self):
        # Add CORS headers for development
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

def get_local_ip():
    """Get the local IP address"""
    try:
        # Connect to a remote address to get the local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except:
        return "127.0.0.1"

def main():
    # Change to the script directory
    os.chdir(Path(__file__).parent)
    
    # Check if build directory exists
    if not os.path.exists(DIRECTORY):
        print(f"Error: {DIRECTORY} directory not found!")
        print("Please run 'flutter build web' first.")
        sys.exit(1)
    
    # Get local IP
    local_ip = get_local_ip()
    
    # Start server
    with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
        print(f"🚀 Flutter Web App Server Started!")
        print(f"📱 Local access: http://localhost:{PORT}")
        print(f"🌐 LAN access: http://{local_ip}:{PORT}")
        print(f"📁 Serving directory: {DIRECTORY}")
        print(f"🔧 Press Ctrl+C to stop the server")
        print("=" * 50)
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 Server stopped by user")
            sys.exit(0)

if __name__ == "__main__":
    main()