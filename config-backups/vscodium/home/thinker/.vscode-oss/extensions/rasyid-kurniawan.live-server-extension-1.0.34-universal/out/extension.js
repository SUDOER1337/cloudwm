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
Object.defineProperty(exports, "__esModule", { value: true });
exports.deactivate = exports.activate = void 0;
const vscode = __importStar(require("vscode"));
const child_process_1 = require("child_process");
const net = __importStar(require("net"));
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const os = __importStar(require("os"));
const httpsonlan_1 = require("./httpsonlan");
let liveServerProcess;
let statusBarItem;
let isServerRunning = false;
let serverUrl = '';
let isPhpProject = false;
let useXampp = false;
let xamppPath = 'C:\\xampp';
let useXamppApache = false;
let autoCopyToHtdocs = false;
let copiedToHtdocs = false;
let htdocsProjectPath = '';
let enableLanAccess = false;
let localIpAddress = '';
let enableHttpsOnLan = false;
let strictWorkspaceRoot = true;
let workspaceRoot;
let workspaceChangeDisposable;
let extensionContext;
function activate(context) {
    console.log('Live Server extension is now active!');
    extensionContext = context;
    workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    // Detect project type
    detectProjectType();
    // Create status bar item
    statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 100);
    statusBarItem.command = 'extension.liveServer.toggle';
    updateStatusBar();
    statusBarItem.show();
    // Register toggle command
    const toggleCommand = vscode.commands.registerCommand('extension.liveServer.toggle', () => {
        if (isServerRunning) {
            stopLiveServer();
        }
        else {
            startLiveServer();
        }
    });
    // Register explicit start and stop commands
    const startCommand = vscode.commands.registerCommand('extension.liveServer.start', () => {
        if (!isServerRunning) {
            startLiveServer();
        }
    });
    const stopCommand = vscode.commands.registerCommand('extension.liveServer.stop', () => {
        if (isServerRunning) {
            stopLiveServer();
        }
    });
    const settingsCommand = vscode.commands.registerCommand('extension.liveServer.settings', () => {
        vscode.commands.executeCommand('workbench.action.openSettings', 'liveServer');
    });
    context.subscriptions.push(toggleCommand, startCommand, stopCommand, settingsCommand, statusBarItem);
    // Detect project type (e.g., PHP)
    detectProjectType();
    // Stop server if workspace folders change (strict mode)
    workspaceChangeDisposable = vscode.workspace.onDidChangeWorkspaceFolders(() => {
        if (strictWorkspaceRoot && isServerRunning) {
            stopLiveServer({ silent: true });
            vscode.window.showWarningMessage('Workspace folders changed. Live Server stopped to prevent serving other project content.');
        }
    });
    if (workspaceChangeDisposable) {
        context.subscriptions.push(workspaceChangeDisposable);
    }
}
exports.activate = activate;
function getLocalIpAddress() {
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
        const iface = interfaces[name];
        if (!iface)
            continue;
        for (const alias of iface) {
            // Skip internal (loopback) and non-IPv4 addresses
            if (alias.family === 'IPv4' && !alias.internal) {
                return alias.address;
            }
        }
    }
    return 'localhost';
}
function updateStatusBar() {
    const serverType = useXamppApache ? 'XAMPP Apache Server' : (useXampp && isPhpProject ? 'XAMPP PHP Server' : (isPhpProject ? 'PHP Server' : 'Live Server'));
    if (isServerRunning) {
        statusBarItem.text = "$(broadcast) Go Live";
        let tooltipText = `${serverType} running at ${serverUrl}`;
        if (enableLanAccess && localIpAddress && localIpAddress !== 'localhost') {
            const lanUrl = serverUrl.replace('localhost', localIpAddress).replace('127.0.0.1', localIpAddress);
            tooltipText += `\nLAN: ${lanUrl}`;
        }
        tooltipText += '. Click to stop.';
        statusBarItem.tooltip = tooltipText;
        statusBarItem.backgroundColor = new vscode.ThemeColor('statusBarItem.warningBackground');
    }
    else {
        statusBarItem.text = "$(circle-large-outline) Go Live";
        statusBarItem.tooltip = `Click to start ${serverType}`;
        statusBarItem.backgroundColor = undefined;
    }
}
async function startLiveServer() {
    const folders = vscode.workspace.workspaceFolders;
    if (!folders || folders.length === 0) {
        vscode.window.showErrorMessage('No workspace folder found. Please open a folder first.');
        return;
    }
    if (strictWorkspaceRoot && folders.length > 1) {
        vscode.window.showErrorMessage('Multiple workspace folders detected. Disable strictWorkspaceRoot or close other folders.');
        return;
    }
    const workspaceFolder = folders[0];
    const workspacePath = workspaceFolder.uri.fsPath;
    if (strictWorkspaceRoot && workspaceRoot && workspaceRoot !== workspacePath) {
        vscode.window.showErrorMessage('Workspace path changed since activation. Reload window or disable strictWorkspaceRoot.');
        return;
    }
    // Always start clean: stop any existing server instances silently
    if (isServerRunning || liveServerProcess) {
        stopLiveServer({ silent: true });
    }
    let httpsConfigPath;
    if (enableLanAccess && enableHttpsOnLan && !isPhpProject && !useXamppApache) {
        if (!extensionContext) {
            vscode.window.showErrorMessage('HTTPS configuration unavailable (extension context missing).');
            return;
        }
        try {
            httpsConfigPath = await (0, httpsonlan_1.ensureHttpsConfig)(extensionContext);
        }
        catch (error) {
            console.error('Failed to prepare HTTPS config:', error);
            vscode.window.showErrorMessage('Failed to prepare HTTPS certificate for LAN access. See console for details.');
            return;
        }
    }
    else if (enableHttpsOnLan && !enableLanAccess) {
        vscode.window.showWarningMessage('Enable LAN Access to serve over HTTPS on LAN.');
    }
    // Get current active file to determine relative path from workspace
    const activeEditor = vscode.window.activeTextEditor;
    let relativePath = '';
    if (activeEditor) {
        const activeFilePath = activeEditor.document.uri.fsPath;
        if (activeFilePath.startsWith(workspacePath)) {
            relativePath = activeFilePath.substring(workspacePath.length).replace(/\\/g, '/');
            // Ensure path starts with /
            if (!relativePath.startsWith('/')) {
                relativePath = '/' + relativePath;
            }
        }
        else if (strictWorkspaceRoot) {
            vscode.window.showWarningMessage('Active file outside workspace root. Deep link ignored.');
        }
    }
    // Check if we should copy to htdocs for Apache
    if (useXamppApache && autoCopyToHtdocs && !copiedToHtdocs) {
        const action = await vscode.window.showInformationMessage('Would you like to copy this project to XAMPP htdocs folder for better Apache compatibility?', 'Copy to htdocs', 'Skip');
        if (action === 'Copy to htdocs') {
            const htdocsPath = await copyProjectToHtdocs(workspacePath);
            if (htdocsPath) {
                copiedToHtdocs = true;
                htdocsProjectPath = htdocsPath;
                // Update relative path to use project name
                const projectName = path.basename(workspacePath);
                if (relativePath) {
                    relativePath = '/' + projectName + relativePath;
                }
            }
        }
    }
    // Choose command based on project type and configuration
    let command = '';
    let shouldStartProcess = true;
    let staticProtocol = 'http';
    if (useXamppApache) {
        // Check if Apache is running
        const isApacheRunning = await checkApacheStatus();
        if (!isApacheRunning) {
            const action = await vscode.window.showWarningMessage('Apache is not running in XAMPP. What would you like to do?', 'Start Apache', 'Open XAMPP Control', 'Cancel');
            if (action === 'Start Apache') {
                // Try to start Apache using XAMPP control
                const success = await startApacheViaXampp();
                if (!success) {
                    vscode.window.showErrorMessage('Failed to start Apache automatically. Please start it manually in XAMPP Control Panel.');
                    return;
                }
                // Wait a bit for Apache to start
                await new Promise(resolve => setTimeout(resolve, 3000));
            }
            else if (action === 'Open XAMPP Control') {
                // Try to open XAMPP Control Panel
                (0, child_process_1.exec)(`"${xamppPath}\\xampp-control.exe"`, (error) => {
                    if (error) {
                        vscode.window.showErrorMessage('Could not open XAMPP Control Panel. Please start Apache manually.');
                    }
                });
                vscode.window.showInformationMessage('Please start Apache in XAMPP Control Panel, then try again.');
                return;
            }
            else {
                return;
            }
        }
        serverUrl = 'http://localhost';
        shouldStartProcess = false;
        // Add relative path for Apache
        if (relativePath) {
            serverUrl += relativePath;
        }
    }
    else if (useXampp && isPhpProject) {
        // Use PHP from XAMPP with -t flag to set document root
        command = `"${xamppPath}\\php\\php.exe" -S localhost:8000 -t "${workspacePath}"`;
    }
    else if (isPhpProject) {
        // Use system PHP with -t flag to set document root
        const host = enableLanAccess ? '0.0.0.0' : 'localhost';
        command = `php -S ${host}:8000 -t "${workspacePath}"`;
    }
    else {
        // Use live-server for static files
        const host = enableLanAccess ? '0.0.0.0' : '127.0.0.1';
        const httpsArgument = httpsConfigPath ? ` --https="${httpsConfigPath}"` : '';
        if (httpsConfigPath) {
            staticProtocol = 'https';
        }
        command = `npx live-server --host=${host}${httpsArgument} --open=./`;
    }
    const serverType = useXamppApache ? 'XAMPP Apache Server' : (useXampp && isPhpProject ? 'XAMPP PHP Server' : (isPhpProject ? 'PHP Server' : 'Live Server'));
    vscode.window.showInformationMessage(`Starting ${serverType}...`);
    if (shouldStartProcess) {
        liveServerProcess = (0, child_process_1.exec)(command, {
            cwd: workspacePath
        }, (error, stdout, stderr) => {
            if (error) {
                console.error(`${serverType} error: ${error}`);
                vscode.window.showErrorMessage(`Failed to start ${serverType}: ${error.message}`);
                isServerRunning = false;
                updateStatusBar();
                return;
            }
        });
    }
    else {
        // For Apache, just set as running and open browser
        isServerRunning = true;
        updateStatusBar();
        vscode.env.openExternal(vscode.Uri.parse(serverUrl));
        return;
    }
    if (liveServerProcess) {
        if (isPhpProject) {
            // For PHP server, set URL immediately and wait a bit for server to start
            setTimeout(() => {
                // Always open in browser using localhost even if LAN mode enabled
                const hostForBrowser = 'localhost';
                serverUrl = `http://${hostForBrowser}:8000`;
                // Add relative path for PHP server
                if (relativePath) {
                    serverUrl += relativePath;
                }
                isServerRunning = true;
                updateStatusBar();
                // Auto-open browser to localhost (not LAN IP) for consistency
                vscode.env.openExternal(vscode.Uri.parse(serverUrl));
                vscode.window.showInformationMessage(`${serverType} started at ${serverUrl}`);
            }, 1500);
        }
        else {
            // Listen for output to get the server URL for live-server
            const protocolForBrowser = staticProtocol;
            liveServerProcess.stdout?.on('data', (data) => {
                console.log(`Live Server: ${data}`);
                // Extract URL and force localhost for browser even in LAN mode
                const urlMatch = data.match(/https?:\/\/([^:\s]+):(\d+)/);
                if (urlMatch) {
                    const port = urlMatch[2];
                    // Always use localhost for browser navigation
                    serverUrl = `${protocolForBrowser}://localhost:${port}`;
                    isServerRunning = true;
                    updateStatusBar();
                    // Auto open browser (always localhost)
                    vscode.env.openExternal(vscode.Uri.parse(serverUrl));
                    vscode.window.showInformationMessage(`Live Server started at ${serverUrl}`);
                }
            });
        }
        liveServerProcess.stderr?.on('data', (data) => {
            console.error(`${serverType} stderr: ${data}`);
        });
        liveServerProcess.on('close', (code) => {
            console.log(`${serverType} process exited with code ${code}`);
            isServerRunning = false;
            serverUrl = '';
            updateStatusBar();
            liveServerProcess = undefined;
        });
        liveServerProcess.on('error', (error) => {
            console.error(`Live Server process error: ${error}`);
            vscode.window.showErrorMessage(`Live Server error: ${error.message}`);
            isServerRunning = false;
            updateStatusBar();
            liveServerProcess = undefined;
        });
        // Set initial status for non-PHP servers
        if (!isPhpProject) {
            isServerRunning = true;
            serverUrl = 'Starting...';
            updateStatusBar();
        }
    }
}
function stopLiveServer(options = {}) {
    const silent = options.silent ?? false;
    const serverType = useXamppApache ? 'XAMPP Apache Server' : (useXampp && isPhpProject ? 'XAMPP PHP Server' : (isPhpProject ? 'PHP Server' : 'Live Server'));
    if (liveServerProcess) {
        // On Windows, we need to kill the process tree
        if (process.platform === 'win32') {
            (0, child_process_1.exec)(`taskkill /pid ${liveServerProcess.pid} /T /F`, (error) => {
                if (error) {
                    console.error(`Error killing process: ${error}`);
                }
            });
        }
        else {
            liveServerProcess.kill();
        }
    }
    if (useXamppApache && !liveServerProcess && !silent) {
        vscode.window.showInformationMessage('Apache continues running in XAMPP Control Panel. Please stop it manually if needed.');
    }
    liveServerProcess = undefined;
    isServerRunning = false;
    serverUrl = '';
    updateStatusBar();
    if (!silent) {
        vscode.window.showInformationMessage(`${serverType} stopped`);
    }
}
function detectProjectType() {
    const workspaceFolder = vscode.workspace.workspaceFolders?.[0];
    if (!workspaceFolder)
        return;
    // Check for PHP files
    vscode.workspace.findFiles('**/*.php', null, 1).then(files => {
        isPhpProject = files.length > 0;
    });
    // Read configuration
    const config = vscode.workspace.getConfiguration('liveServer');
    useXampp = config.get('useXampp', false);
    xamppPath = config.get('xamppPath', 'C:\\xampp');
    useXamppApache = config.get('useXamppApache', false);
    autoCopyToHtdocs = config.get('autoCopyToHtdocs', false);
    enableLanAccess = config.get('enableLanAccess', false);
    enableHttpsOnLan = config.get('enableHttpsOnLan', false);
    strictWorkspaceRoot = config.get('strictWorkspaceRoot', true);
    // Get local IP address if LAN access is enabled
    if (enableLanAccess) {
        localIpAddress = getLocalIpAddress();
        console.log('Local IP Address:', localIpAddress);
    }
}
async function checkApacheStatus() {
    return new Promise((resolve) => {
        const client = net.createConnection({ port: 80, host: 'localhost' }, () => {
            client.end();
            resolve(true);
        });
        client.on('error', () => resolve(false));
        setTimeout(() => {
            client.end();
            resolve(false);
        }, 2000);
    });
}
async function startApacheViaXampp() {
    return new Promise((resolve) => {
        // Try to start Apache using net start command (for Windows service)
        (0, child_process_1.exec)('net start apache2.4', (error, stdout, stderr) => {
            if (error) {
                console.error('Failed to start Apache service:', error);
                resolve(false);
            }
            else {
                console.log('Apache service started successfully');
                resolve(true);
            }
        });
    });
}
async function copyProjectToHtdocs(workspacePath) {
    const htdocsPath = path.join(xamppPath, 'htdocs');
    const projectName = path.basename(workspacePath);
    const targetPath = path.join(htdocsPath, projectName);
    return new Promise((resolve) => {
        // Check if htdocs exists
        if (!fs.existsSync(htdocsPath)) {
            vscode.window.showErrorMessage(`htdocs folder not found at: ${htdocsPath}`);
            resolve(null);
            return;
        }
        // Check if project already exists in htdocs
        if (fs.existsSync(targetPath)) {
            vscode.window.showWarningMessage(`Project "${projectName}" already exists in htdocs. Using existing copy.`);
            resolve(targetPath);
            return;
        }
        // Copy project to htdocs using xcopy (Windows) or cp (Linux/Mac)
        const copyCommand = process.platform === 'win32'
            ? `xcopy "${workspacePath}" "${targetPath}" /E /I /H /Y`
            : `cp -r "${workspacePath}" "${targetPath}"`;
        vscode.window.showInformationMessage('Copying project to htdocs...');
        (0, child_process_1.exec)(copyCommand, (error, stdout, stderr) => {
            if (error) {
                console.error('Copy error:', error);
                vscode.window.showErrorMessage(`Failed to copy project to htdocs: ${error.message}`);
                resolve(null);
            }
            else {
                vscode.window.showInformationMessage(`Project copied to: ${targetPath}`);
                resolve(targetPath);
            }
        });
    });
}
function deactivate() {
    stopLiveServer({ silent: true });
    statusBarItem?.dispose();
}
exports.deactivate = deactivate;
//# sourceMappingURL=extension.js.map