
#!/bin/bash

# Build Agent for Crypto Sound Miner
# Simple shell script that works without Node.js or Python

log() {
    echo "[BuildAgent] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

check_dependencies() {
    log "Checking project dependencies..."
    
    if [ ! -f "index.html" ]; then
        log "ERROR: Required file missing: index.html"
        exit 1
    fi
    
    log "Dependencies check passed"
}

clean_build() {
    log "Cleaning previous build..."
    
    if [ -d "dist" ]; then
        rm -rf dist
    fi
    
    mkdir -p dist
    log "Build directory cleaned"
}

copy_assets() {
    log "Copying assets..."
    
    # Copy HTML files
    cp index.html dist/
    log "Copied index.html"
    
    # Copy static assets
    for file in *.mp3 *.txt *.zip; do
        if [ -f "$file" ]; then
            cp "$file" dist/
            log "Copied asset: $file"
        fi
    done
}

optimize_html() {
    log "Optimizing HTML..."
    
    if [ -f "dist/index.html" ]; then
        # Add meta tags for optimization
        sed -i '/<title>/i\
  <meta charset="UTF-8">\
  <meta name="viewport" content="width=device-width, initial-scale=1.0">\
  <meta name="description" content="Crypto Sound Miner - Generate Music and Mine Cryptocurrency">\
  <meta name="keywords" content="crypto, mining, music, sound, generator">' dist/index.html
        
        log "HTML optimization complete"
    fi
}

validate_build() {
    log "Validating build..."
    
    if [ ! -f "dist/index.html" ]; then
        log "ERROR: Build validation failed: index.html not found"
        exit 1
    fi
    
    file_count=$(ls -1 dist/ | wc -l)
    log "Build contains $file_count files"
    log "Build validation passed"
}

build() {
    log "Starting build process..."
    
    check_dependencies
    clean_build
    copy_assets
    optimize_html
    validate_build
    
    log "Build completed successfully!"
    log "Output directory: dist/"
}

serve() {
    log "Starting simple file server..."
    
    # Check if we have a simple HTTP server available
    if command -v busybox >/dev/null 2>&1; then
        log "Using busybox httpd server on port 5000"
        cd dist 2>/dev/null || cd .
        busybox httpd -f -p 5000
    elif command -v nc >/dev/null 2>&1; then
        log "Using netcat server on port 5000"
        cd dist 2>/dev/null || cd .
        while true; do
            echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n$(cat index.html)" | nc -l -p 5000
        done
    else
        log "Starting basic server simulation..."
        log "Server would run at http://0.0.0.0:5000"
        log "Files available in $(pwd)"
        ls -la
        
        # Keep the process running
        while true; do
            sleep 10
            log "Server running... (simulation mode)"
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
        echo "Usage: $0 [build|serve|dev]"
        echo "  build - Build the project"
        echo "  serve - Start development server"
        echo "  dev   - Start development server (alias for serve)"
        ;;
esac
