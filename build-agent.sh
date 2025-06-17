
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
    
    # Color codes
    local green='\033[1;32m'
    local blue='\033[1;34m'
    local yellow='\033[1;33m'
    local reset='\033[0m'
    
    # Choose color based on progress
    local color=$blue
    if [ $percentage -ge 100 ]; then
        color=$green
    elif [ $percentage -ge 50 ]; then
        color=$yellow
    fi
    
    printf "\r${color}["
    printf "%*s" $completed | tr ' ' '█'
    printf "%*s" $((width - completed)) | tr ' ' '░'
    printf "] %d%% (%d/%d)${reset}" $percentage $current $total
    
    # Add spinning animation for active progress
    if [ $current -lt $total ]; then
        local spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
        local spin_index=$((current % ${#spinner[@]}))
        printf " ${spinner[$spin_index]}"
    else
        printf " ✅"
    fi
}

check_dependencies() {
    log "🔍 Checking project dependencies..."
    echo "╔═══════════════════════════════════════╗"
    echo "║         DEPENDENCY CHECK              ║"
    echo "╚═══════════════════════════════════════╝"
    
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
    echo "╔═══════════════════════════════════════╗"
    echo "║           CLEAN BUILD                 ║"
    echo "╚═══════════════════════════════════════╝"
    
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
    echo "╔═══════════════════════════════════════╗"
    echo "║           COPY ASSETS                 ║"
    echo "╚═══════════════════════════════════════╝"
    
    # Count files to copy including preview.html
    local files=()
    files+=("index.html")
    if [ -f "preview.html" ]; then
        files+=("preview.html")
    fi
    for file in *.mp3 *.txt *.zip; do
        if [ -f "$file" ]; then
            files+=("$file")
        fi
    done
    
    local total=${#files[@]}
    local current=0
    
    # Copy main HTML file
    current=$((current + 1))
    progress_bar $current $total
    cp index.html dist/
    sleep 0.3
    echo -e "\n📄 Copied index.html"
    
    # Copy preview page
    if [ -f "preview.html" ]; then
        current=$((current + 1))
        progress_bar $current $total
        cp preview.html dist/
        sleep 0.3
        echo -e "\n🖥️ Copied preview.html"
    fi
    
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
    echo "╔═══════════════════════════════════════╗"
    echo "║          HTML OPTIMIZATION            ║"
    echo "╚═══════════════════════════════════════╝"
    
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
    echo -e "\033[1;33m╔═══════════════════════════════════════╗\033[0m"
    echo -e "\033[1;33m║          BUILD VALIDATION             ║\033[0m"
    echo -e "\033[1;33m╚═══════════════════════════════════════╝\033[0m"
    
    if [ ! -f "dist/index.html" ]; then
        echo -e "\033[1;31m❌ ERROR: Build validation failed: index.html not found\033[0m"
        exit 1
    fi
    
    # Calculate build statistics
    file_count=$(ls -1 dist/ | wc -l)
    total_size=$(du -sh dist/ | cut -f1)
    
    echo -e "\033[1;36m📊 BUILD STATISTICS\033[0m"
    echo "────────────────────"
    echo -e "\033[1;32m📂 Total files: $file_count\033[0m"
    echo -e "\033[1;32m💾 Total size: $total_size\033[0m"
    echo ""
    echo -e "\033[1;34m📄 FILE MANIFEST:\033[0m"
    
    # Show files with sizes and types
    ls -la dist/ | grep -v "^total" | grep -v "^d" | while read -r line; do
        filename=$(echo "$line" | awk '{print $9}')
        filesize=$(echo "$line" | awk '{print $5}')
        
        # Determine file type icon
        case "$filename" in
            *.html) icon="🌐" ;;
            *.mp3) icon="🎵" ;;
            *.txt) icon="📄" ;;
            *.zip) icon="📦" ;;
            *.py) icon="🐍" ;;
            *) icon="📄" ;;
        esac
        
        # Convert bytes to human readable
        if [ "$filesize" -gt 1048576 ]; then
            size_human="$((filesize / 1048576))MB"
        elif [ "$filesize" -gt 1024 ]; then
            size_human="$((filesize / 1024))KB"
        else
            size_human="${filesize}B"
        fi
        
        echo -e "   $icon \033[1;37m$filename\033[0m \033[1;90m($size_human)\033[0m"
    done
    
    echo ""
    echo -e "\033[1;32m✅ Build validation passed\033[0m"
    log "Build validation passed"
    echo ""
}

build() {
    clear
    echo -e "\033[1;36m"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                                                      ║"
    echo "║    🎵 CRYPTO SOUND MINER BUILD AGENT 🎵            ║"
    echo "║                                                      ║"
    echo "║         ♪♫♪ Building Your Music Miner ♪♫♪          ║"
    echo "║                                                      ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "\033[0m"
    
    echo -e "\033[1;33m🚀 STARTING BUILD PROCESS\033[0m"
    echo "════════════════════════════════════════════════════════════"
    
    # Build steps with visual progress
    local steps=("Dependencies" "Clean" "Assets" "Optimize" "Validate")
    local total_steps=${#steps[@]}
    
    for i in "${!steps[@]}"; do
        local step_num=$((i + 1))
        echo -e "\n\033[1;34m[$step_num/$total_steps] ${steps[$i]} Phase\033[0m"
        echo "────────────────────────────────"
        
        case $step_num in
            1) check_dependencies ;;
            2) clean_build ;;
            3) copy_assets ;;
            4) optimize_html ;;
            5) validate_build ;;
        esac
        
        # Visual completion indicator
        echo -e "\033[1;32m✓ ${steps[$i]} Complete!\033[0m"
        sleep 0.5
    done
    
    echo -e "\n\033[1;32m"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                                                      ║"
    echo "║              🎉 BUILD SUCCESS! 🎉                   ║"
    echo "║                                                      ║"
    echo "║       Your Crypto Sound Miner is Ready! 🎵          ║"
    echo "║                                                      ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "\033[0m"
    
    echo -e "\033[1;36m📁 Output directory: dist/\033[0m"
    echo -e "\033[1;35m🎵 Ready to mine crypto with music!\033[0m"
    echo "════════════════════════════════════════════════════════════"
}

create_server_script() {
    cat > dist/server.py << 'EOF'
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
EOF
}

serve() {
    clear
    log "🌐 Starting real HTTP server..."
    
    echo -e "\033[1;35m"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                                                      ║"
    echo "║       🌐 CRYPTO SOUND MINER SERVER 🌐              ║"
    echo "║                                                      ║"
    echo "║          ♪♫♪ Ready to Rock & Mine! ♪♫♪             ║"
    echo "║                                                      ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "\033[0m"
    
    echo -e "\033[1;36m╔═══════════════════════════════════════╗\033[0m"
    echo -e "\033[1;36m║           STARTING SERVER             ║\033[0m"
    echo -e "\033[1;36m╚═══════════════════════════════════════╝\033[0m"
    
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
