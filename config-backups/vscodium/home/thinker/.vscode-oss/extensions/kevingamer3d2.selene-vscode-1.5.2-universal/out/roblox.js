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
exports.processDiagnostic = void 0;
const vscode = require("vscode");
const util_1 = require("util");
const SETUP_CONFIGURATION = "Setup Configuration";
const ROBLOX_PROBLEMS = new Set(["game", "workspace", "UDim2", "Vector2", "Vector3", "Enum"].map((name) => `\`${name}\` is not defined`));
function processDiagnostic(diagnostic, document) {
    if (ROBLOX_PROBLEMS.has(diagnostic.message)) {
        const workspace = vscode.workspace.getWorkspaceFolder(document.uri);
        if (workspace === undefined) {
            return false;
        }
        if (!vscode.workspace.fs.isWritableFileSystem(workspace.uri.scheme)) {
            return false;
        }
        vscode.window
            .showWarningMessage("It looks like you're trying to lint a Roblox codebase without proper configuration.", SETUP_CONFIGURATION, "Ignore")
            .then((answer) => __awaiter(this, void 0, void 0, function* () {
            if (answer !== SETUP_CONFIGURATION) {
                return;
            }
            const configFilename = vscode.Uri.joinPath(workspace.uri, "selene.toml");
            let configContents;
            try {
                configContents = yield vscode.workspace.fs.readFile(configFilename);
            }
            catch (error) {
                if (error instanceof vscode.FileSystemError &&
                    error.code === "FileNotFound") {
                    configContents = new Uint8Array();
                }
                else {
                    vscode.window.showErrorMessage(`Couldn't read existing config, if there was one.\n\n${typeof error === "object" && error !== null
                        ? error.toString()
                        : error}`);
                    return;
                }
            }
            const contents = new util_1.TextDecoder().decode(configContents);
            vscode.workspace.fs.writeFile(configFilename, new util_1.TextEncoder().encode(addRobloxLibrary(contents)));
        }));
        return true;
    }
    return false;
}
exports.processDiagnostic = processDiagnostic;
// This is a heuristic, but if you're the type of person to know how to break this heuristic
// you're also the type of person to not need this feature
function addRobloxLibrary(contents) {
    let standardLibrarySet = false;
    const lines = contents.split("\n").map((line) => {
        if (!line.startsWith("std")) {
            return line;
        }
        standardLibrarySet = true;
        const match = line.match(/std\s*=\s*"(.+)"/);
        if (match === null) {
            // You are doing something dumb.
            return line;
        }
        return `std = "roblox+${match[1]}"`;
    });
    return standardLibrarySet
        ? lines.join("\n")
        : `std = "roblox"\n${lines.join("\n")}`;
}
//# sourceMappingURL=roblox.js.map