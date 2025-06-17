
#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

class BuildAgent {
  constructor() {
    this.projectRoot = process.cwd();
    this.buildConfig = {
      htmlFiles: ['index.html'],
      staticAssets: ['*.mp3', '*.txt', '*.zip'],
      outputDir: 'dist'
    };
  }

  log(message) {
    console.log(`[BuildAgent] ${new Date().toISOString()} - ${message}`);
  }

  async checkDependencies() {
    this.log('Checking project dependencies...');
    
    // Check if required files exist
    const requiredFiles = ['index.html'];
    for (const file of requiredFiles) {
      if (!fs.existsSync(path.join(this.projectRoot, file))) {
        throw new Error(`Required file missing: ${file}`);
      }
    }
    
    this.log('Dependencies check passed');
  }

  async cleanBuild() {
    this.log('Cleaning previous build...');
    
    if (fs.existsSync(this.buildConfig.outputDir)) {
      fs.rmSync(this.buildConfig.outputDir, { recursive: true, force: true });
    }
    
    fs.mkdirSync(this.buildConfig.outputDir, { recursive: true });
    this.log('Build directory cleaned');
  }

  async copyAssets() {
    this.log('Copying assets...');
    
    // Copy HTML files
    for (const htmlFile of this.buildConfig.htmlFiles) {
      if (fs.existsSync(htmlFile)) {
        fs.copyFileSync(
          path.join(this.projectRoot, htmlFile),
          path.join(this.buildConfig.outputDir, htmlFile)
        );
        this.log(`Copied ${htmlFile}`);
      }
    }

    // Copy static assets
    const files = fs.readdirSync(this.projectRoot);
    for (const file of files) {
      const filePath = path.join(this.projectRoot, file);
      const stat = fs.statSync(filePath);
      
      if (stat.isFile() && (file.endsWith('.mp3') || file.endsWith('.txt') || file.endsWith('.zip'))) {
        fs.copyFileSync(filePath, path.join(this.buildConfig.outputDir, file));
        this.log(`Copied asset: ${file}`);
      }
    }
  }

  async optimizeHTML() {
    this.log('Optimizing HTML...');
    
    const htmlPath = path.join(this.buildConfig.outputDir, 'index.html');
    if (fs.existsSync(htmlPath)) {
      let htmlContent = fs.readFileSync(htmlPath, 'utf8');
      
      // Add meta tags for optimization
      const metaTags = `
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="Crypto Sound Miner - Generate Music and Mine Cryptocurrency">
  <meta name="keywords" content="crypto, mining, music, sound, generator">`;
      
      htmlContent = htmlContent.replace('<title>', metaTags + '\n  <title>');
      
      fs.writeFileSync(htmlPath, htmlContent);
      this.log('HTML optimization complete');
    }
  }

  async validateBuild() {
    this.log('Validating build...');
    
    const distFiles = fs.readdirSync(this.buildConfig.outputDir);
    this.log(`Build contains ${distFiles.length} files: ${distFiles.join(', ')}`);
    
    // Check if main HTML file exists
    if (!distFiles.includes('index.html')) {
      throw new Error('Build validation failed: index.html not found');
    }
    
    this.log('Build validation passed');
  }

  async build() {
    try {
      this.log('Starting build process...');
      
      await this.checkDependencies();
      await this.cleanBuild();
      await this.copyAssets();
      await this.optimizeHTML();
      await this.validateBuild();
      
      this.log('Build completed successfully!');
      this.log(`Output directory: ${this.buildConfig.outputDir}`);
      
    } catch (error) {
      this.log(`Build failed: ${error.message}`);
      process.exit(1);
    }
  }

  async serve() {
    this.log('Starting development server...');
    
    try {
      // Simple HTTP server for development
      const http = require('http');
      const url = require('url');
      
      const server = http.createServer((req, res) => {
        const pathname = url.parse(req.url).pathname;
        let filePath = pathname === '/' ? '/index.html' : pathname;
        filePath = path.join(this.projectRoot, filePath);
        
        if (fs.existsSync(filePath)) {
          const ext = path.extname(filePath);
          const contentType = {
            '.html': 'text/html',
            '.js': 'text/javascript',
            '.css': 'text/css',
            '.mp3': 'audio/mpeg',
            '.txt': 'text/plain'
          }[ext] || 'application/octet-stream';
          
          res.writeHead(200, { 'Content-Type': contentType });
          fs.createReadStream(filePath).pipe(res);
        } else {
          res.writeHead(404);
          res.end('File not found');
        }
      });
      
      server.listen(5000, '0.0.0.0', () => {
        this.log('Server running at http://0.0.0.0:5000');
      });
      
    } catch (error) {
      this.log(`Server failed to start: ${error.message}`);
      process.exit(1);
    }
  }
}

// CLI interface
const command = process.argv[2];
const agent = new BuildAgent();

switch (command) {
  case 'build':
    agent.build();
    break;
  case 'serve':
    agent.serve();
    break;
  case 'dev':
    agent.serve();
    break;
  default:
    console.log('Usage: node build-agent.js [build|serve|dev]');
    console.log('  build - Build the project');
    console.log('  serve - Start development server');
    console.log('  dev   - Start development server (alias for serve)');
}
