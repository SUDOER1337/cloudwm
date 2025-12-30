"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deactivate = exports.activate = void 0;
const vscode_1 = require("vscode");
const node_1 = require("vscode-languageclient/node");
const VIM_MODELINE = /(?:(?:^|[ \t])(?:vi|Vi(?=m))(?:m[<=>]?[0-9]+|m)?|[ \t]ex)(?=:(?=[ \t]*set?[ \t][^\r\n:]+:)|:(?![ \t]*set?[ \t]))(?:(?:[ \t]*:[ \t]*|[ \t])\w*(?:[ \t]*=(?:[^\\\s]|\\.)*)?)*[ \t:](?:filetype|ft|syntax)[ \t]*=(\w+)(?=$|\s|:)/mi;
let client;
let outputChannel;
function startVimLLanguageServer() {
    outputChannel.append('Start VimL Language Server.\n');
    const serverModule = require.resolve('vim-language-server');
    const debugOptions = { execArgv: ['--nolazy', '--inspect=6009'] };
    const serverOptions = {
        run: { module: serverModule, transport: node_1.TransportKind.ipc },
        debug: {
            module: serverModule,
            transport: node_1.TransportKind.ipc,
            options: debugOptions,
        },
    };
    const clientOptions = {
        documentSelector: [{ scheme: 'file', language: 'viml' }],
    };
    client = new node_1.LanguageClient('VimLLanguageServer', 'VimL Language Server', serverOptions, clientOptions);
    client.start();
}
function startVimLLanguageServerWhenVimLFile() {
    if (vscode_1.window.activeTextEditor &&
        vscode_1.window.activeTextEditor.document &&
        vscode_1.window.activeTextEditor.document.languageId === 'viml') {
        startVimLLanguageServer();
        return;
    }
    vscode_1.window.onDidChangeActiveTextEditor((editor) => {
        if (client)
            return;
        if (!editor || !editor.document || editor.document.languageId !== 'viml') {
            return;
        }
        startVimLLanguageServer();
    });
    vscode_1.window.onDidChangeWindowState((e) => {
        if (client)
            return;
        if (!e.focused)
            return;
        if (vscode_1.window.activeTextEditor &&
            vscode_1.window.activeTextEditor.document &&
            vscode_1.window.activeTextEditor.document.languageId === 'viml') {
            startVimLLanguageServer();
        }
    });
}
function tryApplyVimHelpEditorOption(editor, dependsOnHighPriorityConfig = false) {
    if (!editor)
        return;
    if (dependsOnHighPriorityConfig) {
        const config = vscode_1.workspace.getConfiguration('viml');
        const highPriority = config.get('highVimHelpIndentStylePriority');
        if (!highPriority) {
            outputChannel.append('viml.highVimHelpIndentStylePriority is false, ignore.\n');
            return;
        }
        outputChannel.append('viml.highVimHelpIndentStylePriority is true, force indentation.\n');
    }
    outputChannel.append(`Set ${editor.document.fileName}'s indentation\n`);
    editor.options = {
        tabSize: 8,
        insertSpaces: false,
    };
}
function detectIfVimHelp(editor) {
    const document = editor.document;
    // Refer to https://github.com/Alhadis/language-viml/blob/769b532/index.js
    if (/\.txt$/i.test(document.fileName) &&
        VIM_MODELINE.test(document.getText()) &&
        RegExp.lastParen === 'help') {
        outputChannel.append(`vim-help detected on ${document.fileName}.\n`);
        vscode_1.languages.setTextDocumentLanguage(document, 'vim-help');
        tryApplyVimHelpEditorOption(editor, true);
    }
}
function startVimHelpLogic() {
    if (vscode_1.window.activeTextEditor && vscode_1.window.activeTextEditor.document) {
        if (vscode_1.window.activeTextEditor.document.languageId === 'vim-help') {
            tryApplyVimHelpEditorOption(vscode_1.window.activeTextEditor, true);
        }
        else if (![
            'viml',
            'vim-snippet',
        ].includes(vscode_1.window.activeTextEditor.document.languageId)) {
            detectIfVimHelp(vscode_1.window.activeTextEditor);
        }
    }
    vscode_1.window.onDidChangeTextEditorOptions(
    // For EditorConfig
    async (e) => {
        if (e.textEditor &&
            e.textEditor.document &&
            e.textEditor.document.languageId === 'vim-help') {
            if (e.options.tabSize !== 8 || e.options.insertSpaces) {
                tryApplyVimHelpEditorOption(e.textEditor, true);
            }
        }
    });
    vscode_1.window.onDidChangeActiveTextEditor(async (editor) => {
        if (editor && editor.document) {
            if (editor.document.languageId === 'vim-help') {
                tryApplyVimHelpEditorOption(editor);
            }
            else {
                detectIfVimHelp(editor);
            }
        }
    });
    vscode_1.window.onDidChangeWindowState(async (state) => {
        const editor = vscode_1.window.activeTextEditor;
        if (state.focused && editor && editor.document) {
            if (editor.document.languageId === 'vim-help') {
                tryApplyVimHelpEditorOption(editor);
            }
            else {
                detectIfVimHelp(editor);
            }
        }
    });
}
function activate() {
    outputChannel = vscode_1.window.createOutputChannel('VimL');
    startVimLLanguageServerWhenVimLFile();
    startVimHelpLogic();
}
exports.activate = activate;
function deactivate() {
    if (!client)
        return;
    const old = client;
    client = undefined;
    return old.stop();
}
exports.deactivate = deactivate;
//# sourceMappingURL=extension.js.map