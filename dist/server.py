
#!/usr/bin/env python3
import http.server
import socketserver
import os
import json
import mimetypes
import urllib.parse
from datetime import datetime
import threading
import time

class CryptoMinerHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        self.server_stats = {
            'start_time': datetime.now(),
            'requests_count': 0,
            'files_served': 0,
            'mining_sessions': 0,
            'active_connections': 0
        }
        super().__init__(*args, directory=os.getcwd(), **kwargs)
    
    def guess_type(self, path):
        mimetype, encoding = mimetypes.guess_type(path)
        if path.endswith('.mp3'):
            return 'audio/mpeg'
        return mimetype
    
    def do_GET(self):
        self.server_stats['requests_count'] += 1
        parsed_path = urllib.parse.urlparse(self.path)
        path = parsed_path.path
        
        # Dashboard route
        if path == '/dashboard' or path == '/dashboard/':
            self.send_dashboard()
            return
        
        # API routes
        elif path == '/api/stats':
            self.send_api_stats()
            return
        
        elif path == '/api/files':
            self.send_file_browser()
            return
        
        # Serve preview page as default
        elif path == '/':
            if os.path.exists('preview.html'):
                self.path = '/preview.html'
            else:
                self.path = '/index.html'
        
        # Handle app route
        elif path == '/app' or path == '/app/':
            self.path = '/index.html'
        
        # Track file serving
        if os.path.exists(self.path.lstrip('/')):
            self.server_stats['files_served'] += 1
        
        # Default file serving
        return super().do_GET()
    
    def send_dashboard(self):
        dashboard_html = self.generate_dashboard_html()
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(dashboard_html.encode())
    
    def send_api_stats(self):
        uptime = str(datetime.now() - self.server_stats['start_time']).split('.')[0]
        stats = {
            **self.server_stats,
            'uptime': uptime,
            'timestamp': datetime.now().isoformat()
        }
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(stats).encode())
    
    def send_file_browser(self):
        files = []
        for item in os.listdir('.'):
            if os.path.isfile(item):
                stat = os.stat(item)
                files.append({
                    'name': item,
                    'size': stat.st_size,
                    'modified': datetime.fromtimestamp(stat.st_mtime).isoformat(),
                    'type': 'file',
                    'extension': os.path.splitext(item)[1]
                })
        
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(files).encode())
    
    def generate_dashboard_html(self):
        return """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🎵 Crypto Sound Miner - Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            padding: 20px;
        }
        
        .dashboard-container {
            max-width: 1400px;
            margin: 0 auto;
        }
        
        .header {
            text-align: center;
            padding: 20px 0;
            margin-bottom: 30px;
        }
        
        .header h1 {
            font-size: 2.5rem;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.5);
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 20px;
            text-align: center;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        
        .stat-icon {
            font-size: 3rem;
            margin-bottom: 10px;
            display: block;
        }
        
        .stat-value {
            font-size: 2rem;
            font-weight: bold;
            color: #feca57;
            margin-bottom: 5px;
        }
        
        .stat-label {
            font-size: 0.9rem;
            opacity: 0.8;
        }
        
        .charts-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .chart-card {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 20px;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        
        .chart-title {
            font-size: 1.2rem;
            margin-bottom: 15px;
            text-align: center;
        }
        
        .file-browser {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 20px;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        
        .browser-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.2);
        }
        
        .file-list {
            max-height: 400px;
            overflow-y: auto;
        }
        
        .file-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px;
            margin: 5px 0;
            background: rgba(255, 255, 255, 0.05);
            border-radius: 8px;
            transition: background 0.3s ease;
            cursor: pointer;
        }
        
        .file-item:hover {
            background: rgba(255, 255, 255, 0.1);
        }
        
        .file-info {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .file-icon {
            font-size: 1.5rem;
        }
        
        .file-details {
            font-size: 0.8rem;
            opacity: 0.7;
        }
        
        .nav-links {
            text-align: center;
            margin-bottom: 20px;
        }
        
        .nav-links a {
            color: white;
            text-decoration: none;
            padding: 10px 20px;
            margin: 0 10px;
            background: rgba(255, 255, 255, 0.2);
            border-radius: 25px;
            transition: all 0.3s ease;
            display: inline-block;
        }
        
        .nav-links a:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: translateY(-2px);
        }
        
        .refresh-btn {
            background: linear-gradient(45deg, #ff6b6b, #feca57);
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 25px;
            cursor: pointer;
            font-weight: bold;
            transition: transform 0.3s ease;
        }
        
        .refresh-btn:hover {
            transform: translateY(-2px);
        }
        
        @media (max-width: 768px) {
            .charts-grid {
                grid-template-columns: 1fr;
            }
            .stats-grid {
                grid-template-columns: repeat(2, 1fr);
            }
        }
    </style>
</head>
<body>
    <div class="dashboard-container">
        <div class="nav-links">
            <a href="/">🏠 Home</a>
            <a href="/app">🎵 App</a>
            <a href="/dashboard">📊 Dashboard</a>
            <a href="/ADS_POLICY.txt">📋 Policy</a>
        </div>
        
        <div class="header">
            <h1>🎵 Crypto Sound Miner Dashboard</h1>
            <p>Real-time server monitoring and file management</p>
        </div>
        
        <div class="stats-grid" id="statsGrid">
            <!-- Stats will be populated by JavaScript -->
        </div>
        
        <div class="charts-grid">
            <div class="chart-card">
                <h3 class="chart-title">📈 Request Activity</h3>
                <canvas id="requestChart" width="400" height="200"></canvas>
            </div>
            
            <div class="chart-card">
                <h3 class="chart-title">💾 File Usage</h3>
                <canvas id="fileChart" width="400" height="200"></canvas>
            </div>
        </div>
        
        <div class="file-browser">
            <div class="browser-header">
                <h3>📁 File Browser</h3>
                <button class="refresh-btn" onclick="refreshFiles()">🔄 Refresh</button>
            </div>
            <div class="file-list" id="fileList">
                <!-- Files will be populated by JavaScript -->
            </div>
        </div>
    </div>
    
    <script>
        let requestChart, fileChart;
        let requestData = [];
        let timestamps = [];
        
        // Initialize charts
        function initCharts() {
            const ctx1 = document.getElementById('requestChart').getContext('2d');
            requestChart = new Chart(ctx1, {
                type: 'line',
                data: {
                    labels: timestamps,
                    datasets: [{
                        label: 'Requests per minute',
                        data: requestData,
                        borderColor: '#feca57',
                        backgroundColor: 'rgba(254, 202, 87, 0.1)',
                        tension: 0.4
                    }]
                },
                options: {
                    responsive: true,
                    scales: {
                        y: {
                            beginAtZero: true,
                            ticks: { color: 'white' }
                        },
                        x: {
                            ticks: { color: 'white' }
                        }
                    },
                    plugins: {
                        legend: {
                            labels: { color: 'white' }
                        }
                    }
                }
            });
            
            const ctx2 = document.getElementById('fileChart').getContext('2d');
            fileChart = new Chart(ctx2, {
                type: 'doughnut',
                data: {
                    labels: ['MP3 Files', 'HTML Files', 'Text Files', 'Other'],
                    datasets: [{
                        data: [1, 2, 4, 3],
                        backgroundColor: ['#ff6b6b', '#4ecdc4', '#45b7d1', '#96ceb4']
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        legend: {
                            labels: { color: 'white' }
                        }
                    }
                }
            });
        }
        
        // Update dashboard stats
        async function updateStats() {
            try {
                const response = await fetch('/api/stats');
                const stats = await response.json();
                
                const statsGrid = document.getElementById('statsGrid');
                statsGrid.innerHTML = `
                    <div class="stat-card">
                        <span class="stat-icon">🌐</span>
                        <div class="stat-value">${stats.requests_count}</div>
                        <div class="stat-label">Total Requests</div>
                    </div>
                    <div class="stat-card">
                        <span class="stat-icon">📁</span>
                        <div class="stat-value">${stats.files_served}</div>
                        <div class="stat-label">Files Served</div>
                    </div>
                    <div class="stat-card">
                        <span class="stat-icon">⏰</span>
                        <div class="stat-value">${stats.uptime}</div>
                        <div class="stat-label">Uptime</div>
                    </div>
                    <div class="stat-card">
                        <span class="stat-icon">⛏️</span>
                        <div class="stat-value">${stats.mining_sessions}</div>
                        <div class="stat-label">Mining Sessions</div>
                    </div>
                `;
                
                // Update chart data
                const now = new Date().toLocaleTimeString();
                timestamps.push(now);
                requestData.push(stats.requests_count);
                
                if (timestamps.length > 10) {
                    timestamps.shift();
                    requestData.shift();
                }
                
                requestChart.update();
                
            } catch (error) {
                console.error('Error updating stats:', error);
            }
        }
        
        // Load file browser
        async function loadFiles() {
            try {
                const response = await fetch('/api/files');
                const files = await response.json();
                
                const fileList = document.getElementById('fileList');
                fileList.innerHTML = files.map(file => `
                    <div class="file-item" onclick="downloadFile('${file.name}')">
                        <div class="file-info">
                            <span class="file-icon">${getFileIcon(file.extension)}</span>
                            <div>
                                <div>${file.name}</div>
                                <div class="file-details">${formatFileSize(file.size)} • ${new Date(file.modified).toLocaleString()}</div>
                            </div>
                        </div>
                    </div>
                `).join('');
                
                // Update file type chart
                const fileTypes = {};
                files.forEach(file => {
                    const type = getFileType(file.extension);
                    fileTypes[type] = (fileTypes[type] || 0) + 1;
                });
                
                fileChart.data.labels = Object.keys(fileTypes);
                fileChart.data.datasets[0].data = Object.values(fileTypes);
                fileChart.update();
                
            } catch (error) {
                console.error('Error loading files:', error);
            }
        }
        
        function getFileIcon(extension) {
            const icons = {
                '.mp3': '🎵',
                '.html': '🌐',
                '.txt': '📄',
                '.js': '📜',
                '.py': '🐍',
                '.zip': '📦'
            };
            return icons[extension] || '📄';
        }
        
        function getFileType(extension) {
            if (['.mp3', '.wav', '.ogg'].includes(extension)) return 'Audio';
            if (['.html', '.htm'].includes(extension)) return 'HTML';
            if (['.txt', '.md'].includes(extension)) return 'Text';
            if (['.js', '.py', '.sh'].includes(extension)) return 'Code';
            return 'Other';
        }
        
        function formatFileSize(bytes) {
            if (bytes === 0) return '0 B';
            const k = 1024;
            const sizes = ['B', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
        }
        
        function downloadFile(filename) {
            window.open(`/${filename}`, '_blank');
        }
        
        function refreshFiles() {
            loadFiles();
            updateStats();
        }
        
        // Initialize dashboard
        document.addEventListener('DOMContentLoaded', function() {
            initCharts();
            updateStats();
            loadFiles();
            
            // Update every 30 seconds
            setInterval(() => {
                updateStats();
            }, 30000);
            
            console.log('%c🎵 Dashboard Loaded', 'color: #feca57; font-size: 20px; font-weight: bold;');
        });
    </script>
</body>
</html>
        """
    
    def log_message(self, format, *args):
        message = format % args
        timestamp = datetime.now().strftime('%H:%M:%S')
        if '200' in message:
            print(f"✅ [{timestamp}] {message}")
        elif '404' in message:
            print(f"❌ [{timestamp}] {message}")
        else:
            print(f"ℹ️  [{timestamp}] {message}")

# Global stats tracker
stats = {
    'start_time': datetime.now(),
    'requests_count': 0,
    'files_served': 0,
    'mining_sessions': 0
}

PORT = 5000
Handler = CryptoMinerHTTPRequestHandler

print("╔══════════════════════════════════════════════════════╗")
print("║                                                      ║")
print("║       🌐 CRYPTO SOUND MINER SERVER 🌐              ║")
print("║                                                      ║")
print("║          ♪♫♪ Ready to Rock & Mine! ♪♫♪             ║")
print("║                                                      ║")
print("╚══════════════════════════════════════════════════════╝")

print(f"\n🌐 Server starting on port {PORT}")
print(f"🔗 Preview: http://0.0.0.0:{PORT}/")
print(f"🎵 App: http://0.0.0.0:{PORT}/app")
print(f"📊 Dashboard: http://0.0.0.0:{PORT}/dashboard")
print("🚀 Ready to mine crypto with music!")
print("-" * 60)

try:
    with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
        print("✅ Server started successfully!")
        httpd.serve_forever()
except KeyboardInterrupt:
    print("\n🛑 Server stopped by user")
except Exception as e:
    print(f"❌ Server error: {e}")
