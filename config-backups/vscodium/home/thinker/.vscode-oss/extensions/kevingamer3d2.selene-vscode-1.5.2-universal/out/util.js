"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ensureSeleneExists = exports.getSelenePath = exports.downloadSelene = exports.platformIsSupported = exports.getLatestSeleneRelease = void 0;
const os = require("os");
const selene = require("./selene");
const requestNative = require("request");
const request = require("request-promise-native");
const unzip = require("unzipper");
const vscode = require("vscode");
const fsWriteFileAtomic = require("fs-write-stream-atomic");
const GITHUB_RELEASES = "https://summer-bonus-a893.boyned.workers.dev";
let getLatestSeleneReleasePromise;
function getLatestSeleneRelease() {
    return __awaiter(this, void 0, void 0, function* () {
        if (getLatestSeleneReleasePromise) {
            return getLatestSeleneReleasePromise;
        }
        return request(GITHUB_RELEASES, {
            headers: {
                "User-Agent": "selene-vscode",
            },
        }).then((body) => {
            return JSON.parse(body);
        });
    });
}
exports.getLatestSeleneRelease = getLatestSeleneRelease;
function platformIsSupported() {
    switch (os.platform()) {
        case "darwin":
        case "linux":
        case "win32":
            return true;
        default:
            return false;
    }
}
exports.platformIsSupported = platformIsSupported;
function getSeleneFilename() {
    switch (os.platform()) {
        case "win32":
            return "selene.exe";
        case "linux":
        case "darwin":
            return "selene";
        default:
            throw new Error("Platform not supported");
    }
}
function getSeleneFilenamePattern() {
    switch (os.platform()) {
        case "win32":
            return /selene-[^-]+-windows.zip/;
        case "linux":
            return /selene-[^-]+-linux.zip/;
        case "darwin":
            return /selene-[^-]+-macos.zip/;
        default:
            throw new Error("Platform not supported");
    }
}
function fileExists(filename) {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            yield vscode.workspace.fs.stat(filename);
            return true;
        }
        catch (error) {
            if (error instanceof vscode.FileSystemError) {
                return error.code !== "FileNotFound";
            }
            else {
                throw error;
            }
        }
    });
}
function downloadSelene(directory) {
    return __awaiter(this, void 0, void 0, function* () {
        vscode.window.showInformationMessage("Downloading Selene...");
        const filename = getSeleneFilename();
        const filenamePattern = getSeleneFilenamePattern();
        const release = yield getLatestSeleneRelease().catch((error) => {
            vscode.window.showErrorMessage(`Couldn't look for new selene release to download.\n\n${error.toString()}`);
            return Promise.reject(error);
        });
        for (const asset of release.assets) {
            if (filenamePattern.test(asset.name)) {
                const file = fsWriteFileAtomic(vscode.Uri.joinPath(directory, filename).fsPath, {
                    mode: 0o755,
                });
                return new Promise((resolve, reject) => {
                    requestNative(asset.browser_download_url, {
                        headers: {
                            "User-Agent": "selene-vscode",
                        },
                    })
                        .pipe(unzip.Parse())
                        .on("entry", (entry) => {
                        if (entry.path !== filename) {
                            entry.autodrain();
                            return;
                        }
                        entry
                            .pipe(file)
                            .on("finish", resolve)
                            .on("error", reject);
                    });
                });
            }
        }
    });
}
exports.downloadSelene = downloadSelene;
function getSelenePath(storagePath) {
    return __awaiter(this, void 0, void 0, function* () {
        const settingPath = vscode.workspace
            .getConfiguration("selene")
            .get("selenePath");
        if (settingPath) {
            return vscode.Uri.file(settingPath);
        }
        const downloadPath = vscode.Uri.joinPath(storagePath, getSeleneFilename());
        if (yield fileExists(downloadPath)) {
            return downloadPath;
        }
    });
}
exports.getSelenePath = getSelenePath;
function ensureSeleneExists(storagePath) {
    var _a;
    return __awaiter(this, void 0, void 0, function* () {
        const path = yield getSelenePath(storagePath);
        if (path === undefined) {
            yield vscode.workspace.fs.createDirectory(storagePath);
            return downloadSelene(storagePath);
        }
        else {
            if (!(yield fileExists(path))) {
                return Promise.reject("Path given for selene does not exist");
            }
            const version = (_a = (yield selene.seleneCommand(storagePath, "--version", selene.Expectation.Stdout))) === null || _a === void 0 ? void 0 : _a.trim();
            return getLatestSeleneRelease()
                .then((release) => {
                if (version !== `selene ${release.tag_name}`) {
                    openUpdatePrompt(storagePath, release);
                }
            })
                .catch((error) => {
                vscode.window.showErrorMessage(`Couldn't look for new selene releases.\n\n${error.toString()}`);
            });
        }
    });
}
exports.ensureSeleneExists = ensureSeleneExists;
function openUpdatePrompt(directory, release) {
    vscode.window
        .showInformationMessage(`There's an update available for selene: ${release.tag_name}`, "Install Update", "Later", "Release Notes")
        .then((option) => {
        switch (option) {
            case "Install Update":
                downloadSelene(directory).then(() => vscode.window.showInformationMessage("Update succeeded."));
                break;
            case "Release Notes":
                vscode.env.openExternal(vscode.Uri.parse(release.html_url));
                openUpdatePrompt(directory, release);
                break;
        }
    });
}
//# sourceMappingURL=util.js.map