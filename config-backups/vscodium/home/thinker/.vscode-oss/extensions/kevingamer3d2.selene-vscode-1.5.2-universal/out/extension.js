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
exports.deactivate = exports.activate = void 0;
const roblox = require("./roblox");
const selene = require("./selene");
const timers = require("timers");
const util = require("./util");
const vscode = require("vscode");
const path = require("path");
const fs = require("fs");
const toml = require("toml");
const micromatch = require("micromatch");
const diagnostic_1 = require("./structures/diagnostic");
const configLint_1 = require("./configLint");
const byteToCharMap_1 = require("./byteToCharMap");
let trySelene;
var RunType;
(function (RunType) {
    RunType["OnSave"] = "onSave";
    RunType["OnType"] = "onType";
    RunType["OnNewLine"] = "onNewLine";
    RunType["OnIdle"] = "onIdle";
})(RunType || (RunType = {}));
function labelToRange(document, label, byteOffsetMap) {
    var _a, _b;
    return new vscode.Range(document.positionAt((_a = byteOffsetMap.get(label.span.start)) !== null && _a !== void 0 ? _a : label.span.start), document.positionAt((_b = byteOffsetMap.get(label.span.end)) !== null && _b !== void 0 ? _b : label.span.end));
}
function activate(context) {
    return __awaiter(this, void 0, void 0, function* () {
        console.log("selene-vscode activated");
        let capabilities = {};
        trySelene = util
            .ensureSeleneExists(context.globalStorageUri)
            .then(() => {
            selene
                .seleneCommand(context.globalStorageUri, "capabilities --display-style=json2", selene.Expectation.Stdout)
                .then((output) => {
                if (output === null) {
                    return;
                }
                capabilities = JSON.parse(output.toString());
            })
                .catch(() => {
                // selene version is too old
                return;
            });
        })
            .then(() => {
            return true;
        })
            .catch((error) => {
            vscode.window.showErrorMessage(`An error occurred when finding selene:\n${error}`);
            return false;
        });
        yield trySelene;
        context.subscriptions.push(vscode.commands.registerCommand("selene.reinstall", () => {
            trySelene = util
                .downloadSelene(context.globalStorageUri)
                .then(() => true)
                .catch(() => false);
            return trySelene;
        }), vscode.commands.registerCommand("selene.update-roblox-std", () => __awaiter(this, void 0, void 0, function* () {
            const output = yield selene
                .seleneCommand(context.globalStorageUri, "update-roblox-std", selene.Expectation.Stdout)
                .catch((error) => {
                vscode.window.showErrorMessage(`Couldn't update Roblox standard library: \n${error}`);
                return false;
            });
            vscode.window.showInformationMessage((output === null || output === void 0 ? void 0 : output.toString()) || "");
        })), vscode.commands.registerCommand("selene.generate-roblox-std", () => __awaiter(this, void 0, void 0, function* () {
            const output = yield selene
                .seleneCommand(context.globalStorageUri, "generate-roblox-std", selene.Expectation.Stdout)
                .catch((error) => {
                vscode.window.showErrorMessage(`Couldn't create Roblox standard library: \n${error}`);
                return false;
            });
            vscode.window.showInformationMessage((output === null || output === void 0 ? void 0 : output.toString()) || "");
        })));
        const diagnosticsCollection = vscode.languages.createDiagnosticCollection("selene");
        context.subscriptions.push(diagnosticsCollection);
        let hasWarnedAboutRoblox = false;
        function lint(document) {
            return __awaiter(this, void 0, void 0, function* () {
                if (!(yield trySelene)) {
                    return;
                }
                switch (document.languageId) {
                    case "lua":
                    case "luau":
                        break;
                    case "toml":
                    case "yaml":
                        yield (0, configLint_1.lintConfig)(capabilities, context, document, diagnosticsCollection);
                        return;
                    default:
                        return;
                }
                const workspaceFolder = vscode.workspace.getWorkspaceFolder(document.uri);
                const workspaceRoot = workspaceFolder === null || workspaceFolder === void 0 ? void 0 : workspaceFolder.uri.fsPath;
                if (!workspaceRoot) {
                    console.error("Failed to find workspace root");
                    return;
                }
                const configPath = path.join(workspaceRoot, "selene.toml");
                let config = {};
                try {
                    const configFileContent = fs.readFileSync(configPath, "utf-8");
                    config = toml.parse(configFileContent);
                }
                catch (error) {
                    config = undefined;
                }
                if (config) {
                    // We don't invoke selene on the files directly as it won't work on unsaved changes, so we
                    // need to check for exclude paths separately
                    const shouldExclude = (config.exclude || []).some((pattern) => {
                        // Document path given is absolute so the patterns should be as well
                        // If multiple `selene.toml` becomes supported, this will likely need to be changed to support it.
                        const excludeGlobAbsolute = path.isAbsolute(pattern)
                            ? pattern
                            : path.join(workspaceRoot, pattern);
                        return micromatch.isMatch(document.uri.fsPath.replace(/\\/g, "/"), excludeGlobAbsolute.replace(/\\/g, "/"), {
                            bash: true,
                        });
                    });
                    if (shouldExclude) {
                        diagnosticsCollection.delete(document.uri);
                        return;
                    }
                }
                const output = yield selene.seleneCommand(context.globalStorageUri, "--display-style=json2 --no-summary -", selene.Expectation.Stderr, workspaceFolder, document.getText());
                if (!output) {
                    diagnosticsCollection.delete(document.uri);
                    return;
                }
                const diagnostics = [];
                const dataToAdd = [];
                const byteOffsets = new Set();
                for (const line of output.split("\n")) {
                    if (!line) {
                        continue;
                    }
                    let output;
                    try {
                        output = JSON.parse(line);
                    }
                    catch (_a) {
                        console.error(`Couldn't parse output: ${line}`);
                        continue;
                    }
                    switch (output.type) {
                        case "Diagnostic":
                            dataToAdd.push(output);
                            byteOffsets.add(output.primary_label.span.start);
                            byteOffsets.add(output.primary_label.span.end);
                            for (const label of output.secondary_labels) {
                                byteOffsets.add(label.span.start);
                                byteOffsets.add(label.span.end);
                            }
                            break;
                        case "InvalidConfig":
                            break;
                    }
                }
                const byteOffsetMap = (0, byteToCharMap_1.byteToCharMap)(document, byteOffsets);
                for (const data of dataToAdd) {
                    let message = data.message;
                    if (data.primary_label.message.length > 0) {
                        message += `\n${data.primary_label.message}`;
                    }
                    if (data.notes.length > 0) {
                        message += `\n${data.notes.map((note) => `note: ${note}\n`)}`;
                    }
                    const diagnostic = new vscode.Diagnostic(labelToRange(document, data.primary_label, byteOffsetMap), message, data.severity === diagnostic_1.Severity.Error
                        ? vscode.DiagnosticSeverity.Error
                        : vscode.DiagnosticSeverity.Warning);
                    diagnostic.source = `selene::${data.code}`;
                    if (data.code === "unused_variable") {
                        diagnostic.tags = [vscode.DiagnosticTag.Unnecessary];
                    }
                    diagnostic.relatedInformation = data.secondary_labels.map((label) => {
                        return {
                            message: label.message,
                            location: {
                                uri: document.uri,
                                range: labelToRange(document, label, byteOffsetMap),
                            },
                        };
                    });
                    if (vscode.workspace
                        .getConfiguration("selene")
                        .get("warnRoblox")) {
                        if (!hasWarnedAboutRoblox &&
                            roblox.processDiagnostic(data, document)) {
                            hasWarnedAboutRoblox = true;
                        }
                    }
                    diagnostics.push(diagnostic);
                }
                diagnosticsCollection.set(document.uri, diagnostics);
            });
        }
        let lastTimeout;
        function listenToChange() {
            switch (vscode.workspace.getConfiguration("selene").get("run")) {
                case RunType.OnSave:
                    return vscode.workspace.onDidSaveTextDocument(lint);
                case RunType.OnType:
                    return vscode.workspace.onDidChangeTextDocument((event) => lint(event.document));
                case RunType.OnNewLine:
                    return vscode.workspace.onDidChangeTextDocument((event) => {
                        // Contrary to removing lines, adding new lines will leave the range at the same value hence the string comparisons
                        if (event.contentChanges.some((content) => !content.range.isSingleLine ||
                            content.text === "\n" ||
                            content.text === "\r\n")) {
                            lint(event.document);
                        }
                    });
                case RunType.OnIdle: {
                    const idleDelay = vscode.workspace
                        .getConfiguration("selene")
                        .get("idleDelay");
                    return vscode.workspace.onDidChangeTextDocument((event) => {
                        timers.clearTimeout(lastTimeout);
                        lastTimeout = timers.setTimeout(lint, idleDelay, event.document);
                    });
                }
            }
        }
        let disposable = listenToChange();
        vscode.workspace.onDidChangeConfiguration((event) => {
            if (event.affectsConfiguration("selene.run") ||
                event.affectsConfiguration("selene.idleDelay")) {
                disposable === null || disposable === void 0 ? void 0 : disposable.dispose();
                disposable = listenToChange();
            }
        });
        vscode.workspace.onDidOpenTextDocument(lint);
        vscode.workspace.onWillDeleteFiles((event) => {
            for (const documentUri of event.files) {
                diagnosticsCollection.set(documentUri, []);
            }
        });
        vscode.window.onDidChangeActiveTextEditor((editor) => {
            if (editor !== undefined) {
                lint(editor.document);
            }
        });
    });
}
exports.activate = activate;
// this method is called when your extension is deactivated
function deactivate() {
    return;
}
exports.deactivate = deactivate;
//# sourceMappingURL=extension.js.map