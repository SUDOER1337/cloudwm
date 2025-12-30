"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.LiveServer = void 0;
const vscode = __importStar(require("vscode"));
const express_1 = __importDefault(require("express"));
const path = __importStar(require("path"));
const fs = __importStar(require("fs"));
const http = __importStar(require("http"));
const chokidar = __importStar(require("chokidar"));
const ws_1 = __importStar(require("ws"));
class LiveServer {
    constructor() {
        this.isRunning = false;
        this.port = 5500;
        this.app = (0, express_1.default)();
        this.statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
        this.setupStatusBar();
    }
    setupStatusBar() {
        this.statusBarItem.text = "$(circle-large-outline) Live Server";
        this.statusBarItem.tooltip = "Click to start Live Server";
        this.statusBarItem.command = "extension.liveServer.start";
        this.statusBarItem.show();
    }
    updateStatusBar(running) {
        if (running) {
            this.statusBarItem.text = `$(radio-tower) Live Server: ${this.port}`;
            this.statusBarItem.tooltip = `Live Server running on port ${this.port}. Click to stop.`;
            this.statusBarItem.command = "extension.liveServer.stop";
            this.statusBarItem.backgroundColor = undefined;
        }
        else {
            this.statusBarItem.text = "$(circle-large-outline) Live Server";
            this.statusBarItem.tooltip = "Click to start Live Server";
            this.statusBarItem.command = "extension.liveServer.start";
            this.statusBarItem.backgroundColor = undefined;
        }
    }
    async start(rootPath) {
        if (this.isRunning) {
            vscode.window.showInformationMessage('Live Server is already running');
            return;
        }
        try {
            // Get configuration
            const config = vscode.workspace.getConfiguration('liveServer');
            this.port = config.get('port') || 5500;
            const host = config.get('host') || '127.0.0.1';
            // Find an available port
            this.port = await this.findAvailablePort(this.port);
            // Setup express app
            this.setupExpressApp(rootPath);
            // Create HTTP server
            this.server = http.createServer(this.app);
            // Setup WebSocket for live reload
            this.setupWebSocket();
            // Setup file watcher
            this.setupFileWatcher(rootPath);
            // Start server
            await new Promise((resolve, reject) => {
                this.server.listen(this.port, host, () => {
                    this.isRunning = true;
                    this.updateStatusBar(true);
                    const url = `http://${host}:${this.port}`;
                    vscode.window.showInformationMessage(`Live Server started on ${url}`, 'Open Browser').then((selection) => {
                        if (selection === 'Open Browser') {
                            vscode.env.openExternal(vscode.Uri.parse(url));
                        }
                    });
                    resolve();
                });
                this.server.on('error', (error) => {
                    reject(error);
                });
            });
        }
        catch (error) {
            vscode.window.showErrorMessage(`Failed to start Live Server: ${error}`);
            throw error;
        }
    }
    async stop() {
        if (!this.isRunning) {
            vscode.window.showInformationMessage('Live Server is not running');
            return;
        }
        try {
            // Stop file watcher
            if (this.watcher) {
                await this.watcher.close();
                this.watcher = undefined;
            }
            // Close WebSocket server
            if (this.wss) {
                this.wss.close();
                this.wss = undefined;
            }
            // Close HTTP server
            if (this.server) {
                await new Promise((resolve) => {
                    this.server.close(() => {
                        resolve();
                    });
                });
                this.server = undefined;
            }
            this.isRunning = false;
            this.updateStatusBar(false);
            vscode.window.showInformationMessage('Live Server stopped');
        }
        catch (error) {
            vscode.window.showErrorMessage(`Failed to stop Live Server: ${error}`);
            throw error;
        }
    }
    setupExpressApp(rootPath) {
        // Serve static files
        this.app.use(express_1.default.static(rootPath));
        // Inject live reload script into HTML files
        this.app.get('*.html', (req, res, next) => {
            const filePath = path.join(rootPath, req.path);
            if (fs.existsSync(filePath)) {
                let html = fs.readFileSync(filePath, 'utf8');
                // Inject live reload script before closing body tag
                const liveReloadScript = `
                <script>
                    (function() {
                        const ws = new WebSocket('ws://localhost:${this.port + 1}');
                        ws.onmessage = function(event) {
                            if (event.data === 'reload') {
                                window.location.reload();
                            }
                        };
                        ws.onclose = function() {
                            console.log('Live reload disconnected');
                        };
                    })();
                </script>`;
                if (html.includes('</body>')) {
                    html = html.replace('</body>', `${liveReloadScript}</body>`);
                }
                else {
                    html += liveReloadScript;
                }
                res.send(html);
            }
            else {
                next();
            }
        });
        // Handle SPA routing - serve index.html for non-file routes
        this.app.get('*', (req, res) => {
            const indexPath = path.join(rootPath, 'index.html');
            if (fs.existsSync(indexPath)) {
                res.sendFile(indexPath);
            }
            else {
                res.status(404).send('File not found');
            }
        });
    }
    setupWebSocket() {
        // Create WebSocket server on port + 1
        this.wss = new ws_1.WebSocketServer({ port: this.port + 1 });
        this.wss.on('connection', (ws) => {
            ws.on('error', (error) => {
                console.error('WebSocket error:', error);
            });
        });
    }
    setupFileWatcher(rootPath) {
        this.watcher = chokidar.watch(rootPath, {
            ignored: /node_modules|\.git/,
            persistent: true,
            ignoreInitial: true
        });
        this.watcher.on('change', () => {
            this.broadcastReload();
        });
        this.watcher.on('add', () => {
            this.broadcastReload();
        });
        this.watcher.on('unlink', () => {
            this.broadcastReload();
        });
    }
    broadcastReload() {
        if (this.wss) {
            this.wss.clients.forEach((client) => {
                if (client.readyState === ws_1.default.OPEN) {
                    client.send('reload');
                }
            });
        }
    }
    async findAvailablePort(startPort) {
        return new Promise((resolve) => {
            const server = http.createServer();
            server.listen(startPort, () => {
                const port = server.address()?.port;
                server.close(() => {
                    resolve(port || startPort);
                });
            });
            server.on('error', () => {
                resolve(this.findAvailablePort(startPort + 1));
            });
        });
    }
    dispose() {
        this.stop();
        this.statusBarItem.dispose();
    }
}
exports.LiveServer = LiveServer;
//# sourceMappingURL=liveServer.js.map