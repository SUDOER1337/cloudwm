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
exports.seleneCommand = exports.Expectation = void 0;
const childProcess = require("child_process");
const vscode = require("vscode");
const util = require("./util");
var Expectation;
(function (Expectation) {
    Expectation[Expectation["Stderr"] = 0] = "Stderr";
    Expectation[Expectation["Stdout"] = 1] = "Stdout";
})(Expectation = exports.Expectation || (exports.Expectation = {}));
function seleneCommand(storagePath, command, expectation, workspace, stdin) {
    return __awaiter(this, void 0, void 0, function* () {
        return util.getSelenePath(storagePath).then((selenePath) => {
            return new Promise((resolve, reject) => {
                var _a, _b, _c, _d;
                if (selenePath === undefined) {
                    return reject("Could not find selene.");
                }
                const workspaceFolders = vscode.workspace.workspaceFolders;
                const child = childProcess.exec(`"${selenePath.fsPath}" ${command}`, {
                    cwd: (workspace === null || workspace === void 0 ? void 0 : workspace.uri.fsPath) ||
                        ((_b = (_a = (workspaceFolders && workspaceFolders[0])) === null || _a === void 0 ? void 0 : _a.uri) === null || _b === void 0 ? void 0 : _b.fsPath),
                }, (error, stdout) => {
                    if (expectation === Expectation.Stderr) {
                        resolve(error && stdout);
                    }
                    else {
                        if (error) {
                            reject(error);
                        }
                        else {
                            resolve(stdout);
                        }
                    }
                });
                if (stdin !== undefined) {
                    (_c = child.stdin) === null || _c === void 0 ? void 0 : _c.write(stdin);
                    (_d = child.stdin) === null || _d === void 0 ? void 0 : _d.end();
                }
            });
        });
    });
}
exports.seleneCommand = seleneCommand;
//# sourceMappingURL=selene.js.map