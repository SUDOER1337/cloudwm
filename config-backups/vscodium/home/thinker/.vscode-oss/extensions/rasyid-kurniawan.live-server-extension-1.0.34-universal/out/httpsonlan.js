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
exports.ensureHttpsConfig = void 0;
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const os = __importStar(require("os"));
const CERT_FILE = 'lan-cert.pem';
const KEY_FILE = 'lan-key.pem';
const CONFIG_FILE = 'lan-https.json';
async function ensureDir(dir) {
    await fs.promises.mkdir(dir, { recursive: true });
}
function getStoragePath(context) {
    if (context.globalStorageUri) {
        return context.globalStorageUri.fsPath;
    }
    if (context.globalStoragePath) {
        return context.globalStoragePath;
    }
    return path.join(os.tmpdir(), 'live-server');
}
async function generateCertificates(certPath, keyPath) {
    const attrs = [{ name: 'commonName', value: 'Live Server LAN' }];
    const options = {
        days: 365,
        keySize: 2048,
        algorithm: 'sha256'
    };
    let selfsignedModule;
    try {
        selfsignedModule = await Promise.resolve().then(() => __importStar(require('selfsigned')));
    }
    catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        throw new Error(`Failed to load selfsigned dependency: ${message}`);
    }
    const generator = selfsignedModule.default ?? selfsignedModule;
    const pems = generator.generate(attrs, options);
    await fs.promises.writeFile(certPath, pems.cert, { encoding: 'utf8' });
    await fs.promises.writeFile(keyPath, pems.private, { encoding: 'utf8' });
}
async function ensureHttpsConfig(context) {
    const storageDir = path.join(getStoragePath(context), 'https');
    await ensureDir(storageDir);
    const certPath = path.join(storageDir, CERT_FILE);
    const keyPath = path.join(storageDir, KEY_FILE);
    const configPath = path.join(storageDir, CONFIG_FILE);
    const certExists = fs.existsSync(certPath);
    const keyExists = fs.existsSync(keyPath);
    if (!certExists || !keyExists) {
        await generateCertificates(certPath, keyPath);
    }
    const httpsConfig = {
        cert: certPath,
        key: keyPath
    };
    await fs.promises.writeFile(configPath, JSON.stringify(httpsConfig, null, 2), { encoding: 'utf8' });
    return configPath;
}
exports.ensureHttpsConfig = ensureHttpsConfig;
//# sourceMappingURL=httpsonlan.js.map