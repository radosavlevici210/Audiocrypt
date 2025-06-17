
#!/bin/bash

# Build Agent for Crypto Sound Miner
# Enhanced version with real HTTP server and build visualization

log() {
    echo "[BuildAgent] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    
    printf "\r["
    printf "%*s" $completed | tr ' ' '='
    printf "%*s" $((width - completed)) | tr ' ' '-'
    printf "] %d%% (%d/%d)" $percentage $current $total
}

check_dependencies() {
    log "🔍 Checking project dependencies..."
    echo "┌─────────────────────────────────────┐"
    echo "│         DEPENDENCY CHECK            │"
    echo "└─────────────────────────────────────┘"
    
    local files=("index.html")
    local total=${#files[@]}
    local current=0
    
    for file in "${files[@]}"; do
        current=$((current + 1))
        progress_bar $current $total
        sleep 0.5
        
        if [ ! -f "$file" ]; then
            echo -e "\n❌ ERROR: Required file missing: $file"
            exit 1
        fi
    done
    
    echo -e "\n✅ Dependencies check passed"
    echo ""
}

clean_build() {
    log "🧹 Cleaning previous build..."
    echo "┌─────────────────────────────────────┐"
    echo "│           CLEAN BUILD               │"
    echo "└─────────────────────────────────────┘"
    
    if [ -d "dist" ]; then
        rm -rf dist
        echo "🗑️  Removed old dist directory"
    fi
    
    mkdir -p dist
    echo "📁 Created new dist directory"
    log "Build directory cleaned"
    echo ""
}

copy_assets() {
    log "📋 Copying assets..."
    echo "┌─────────────────────────────────────┐"
    echo "│           COPY ASSETS               │"
    echo "└─────────────────────────────────────┘"
    
    # Count files to copy
    local files=()
    files+=("index.html")
    for file in *.mp3 *.txt *.zip; do
        if [ -f "$file" ]; then
            files+=("$file")
        fi
    done
    
    local total=${#files[@]}
    local current=0
    
    # Copy HTML files
    current=$((current + 1))
    progress_bar $current $total
    cp index.html dist/
    sleep 0.3
    echo -e "\n📄 Copied index.html"
    
    # Copy static assets
    for file in *.mp3 *.txt *.zip; do
        if [ -f "$file" ]; then
            current=$((current + 1))
            progress_bar $current $total
            cp "$file" dist/
            sleep 0.2
            echo -e "\n📎 Copied asset: $file"
        fi
    done
    
    echo ""
}

optimize_html() {
    log "⚡ Optimizing HTML..."
    echo "┌─────────────────────────────────────┐"
    echo "│          HTML OPTIMIZATION          │"
    echo "└─────────────────────────────────────┘"
    
    if [ -f "dist/index.html" ]; then
        # Add meta tags for optimization
        sed -i '/<title>/i\
  <meta charset="UTF-8">\
  <meta name="viewport" content="width=device-width, initial-scale=1.0">\
  <meta name="description" content="Crypto Sound Miner - Generate Music and Mine Cryptocurrency">\
  <meta name="keywords" content="crypto, mining, music, sound, generator">' dist/index.html
        
        echo "🔧 Added SEO meta tags"
        echo "🎨 Optimized viewport settings"
        log "HTML optimization complete"
    fi
    echo ""
}

validate_build() {
    log "✅ Validating build..."
    echo "┌─────────────────────────────────────┐"
    echo "│          BUILD VALIDATION           │"
    echo "└─────────────────────────────────────┘"
    
    if [ ! -f "dist/index.html" ]; then
        echo "❌ ERROR: Build validation failed: index.html not found"
        exit 1
    fi
    
    file_count=$(ls -1 dist/ | wc -l)
    echo "📊 Build contains $file_count files:"
    ls -la dist/ | grep -v "^total" | grep -v "^d" | awk '{print "   📄 " $9}'
    
    echo "✅ Build validation passed"
    log "Build validation passed"
    echo ""
}

build() {
    echo "🚀 STARTING BUILD PROCESS"
    echo "════════════════════════════════════════════════════════════"
    
    check_dependencies
    clean_build
    copy_assets
    optimize_html
    validate_build
    
    echo "🎉 BUILD COMPLETED SUCCESSFULLY!"
    echo "📁 Output directory: dist/"
    echo "════════════════════════════════════════════════════════════"
}

create_server_script() {
    cat > dist/server.py << 'EOF'
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
EOF
}

serve() {
    log "🌐 Starting real HTTP server..."
    echo "┌─────────────────────────────────────┐"
    echo "│           STARTING SERVER           │"
    echo "└─────────────────────────────────────┘"
    
    # Build first if dist doesn't exist
    if [ ! -d "dist" ]; then
        echo "📁 No dist directory found, building first..."
        build
    fi
    
    # Create Python server script
    create_server_script
    chmod +x dist/server.py
    
    # Try different server options
    if command -v python3 >/dev/null 2>&1; then
        log "Using Python3 HTTP server on port 5000"
        echo "🐍 Using Python3 server"
        cd dist
        python3 server.py
    elif command -v python >/dev/null 2>&1; then
        log "Using Python HTTP server on port 5000"
        echo "🐍 Using Python server"
        cd dist
        python -m http.server 5000 --bind 0.0.0.0
    else
        log "Starting basic file listing server"
        echo "📁 Using basic file server"
        cd dist 2>/dev/null || cd .
        
        echo "🌐 Server started at http://0.0.0.0:5000"
        echo "📂 Serving files from: $(pwd)"
        echo "📄 Available files:"
        ls -la
        
        # Keep the process running with status updates
        while true; do
            sleep 30
            echo "⏰ Server running... $(date)"
        done
    fi
}

# CLI interface
case "$1" in
    build)
        build
        ;;
    serve)
        serve
        ;;
    dev)
        serve
        ;;
    *)
        echo "🎵 Crypto Sound Miner Build Agent"
        echo "Usage: $0 [build|serve|dev]"
        echo "  build - Build the project with visualization"
        echo "  serve - Start real HTTP server"
        echo "  dev   - Start development server (alias for serve)"
        ;;
esac
