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
exports.lintConfig = void 0;
const vscode = require("vscode");
const selene = require("./selene");
const capabilities_1 = require("./structures/capabilities");
function lintConfig(capabilities, context, document, diagnosticsCollection) {
    return __awaiter(this, void 0, void 0, function* () {
        if (!(0, capabilities_1.capability)(capabilities, "validateConfig", "1")) {
            return;
        }
        if (document.languageId === "toml" &&
            !document.uri.path.endsWith("selene.toml")) {
            return;
        }
        const workspaceFolder = vscode.workspace.getWorkspaceFolder(document.uri);
        const tomlSource = document.languageId === "toml" ? "--stdin" : "";
        const output = yield selene.seleneCommand(context.globalStorageUri, `validate-config --display-style=json2 ${tomlSource}`, selene.Expectation.Stderr, workspaceFolder, document.getText());
        if (output === null) {
            diagnosticsCollection.delete(document.uri);
            return;
        }
        const diagnostics = [];
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
            if (output.type !== "InvalidConfig") {
                continue;
            }
            if (document.uri.fsPath !== output.source && output.source !== "-") {
                continue;
            }
            const range = output.range
                ? new vscode.Range(document.positionAt(output.range.start), document.positionAt(output.range.end))
                : new vscode.Range(document.lineAt(0).range.start, document.lineAt(document.lineCount - 1).range.end);
            diagnostics.push(new vscode.Diagnostic(range, output.error, vscode.DiagnosticSeverity.Error));
        }
        diagnosticsCollection.set(document.uri, diagnostics);
    });
}
exports.lintConfig = lintConfig;
//# sourceMappingURL=configLint.js.map