'use strict';
// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
var vscode = require('vscode');
var beautify = require('js-beautify').js_beautify;
function toObject(value) {
    var values = [];
    if (value === null) {
        return "null";
    }
    else if (typeof value === 'string') {
        value = JSON.stringify(value).slice(1, -1);
        return "'" + value.replace('\'', '\\\'') + "'";
    }
    else if (typeof value === 'number' || typeof value === 'boolean') {
        return "" + value;
    }
    else if (value instanceof Array) {
        values = ["[", value.map(function (v) { return toObject(v); }).join(","), "]"];
    }
    else if (typeof value === 'object') {
        values = ["{", Object.keys(value).map(function (v) {
                var key = /[^a-zA-Z0-9]/.test(v) ? "'" + v + "'" : v;
                return key + ": " + toObject(value[v]);
            }).join(","), "}"];
    }
    return values.join('');
}
exports.toObject = toObject;
function doAction(text) {
    var output;
    try {
        var target = JSON.parse(text);
        output = toObject(target);
    }
    catch (e) {
        console.warn(e);
    }
    if (output == undefined) {
        try {
            var target = eval('(' + text + ')');
            output = JSON.stringify(target, null, 4);
        }
        catch (e) {
            console.warn(e);
        }
    }
    return output && beautify(output);
}
exports.doAction = doAction;
// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
function activate(context) {
    // The command has been defined in the package.json file
    // Now provide the implementation of the command with  registerCommand
    // The commandId parameter must match the command field in package.json
    var disposable = vscode.commands.registerCommand('jsono.toggleFormat', function () {
        // The code you place here will be executed every time your command is executed
        var editor = vscode.window.activeTextEditor;
        if (!editor) {
            return; // No open text editor
        }
        var selection = editor.selection;
        var text = editor.document.getText(selection);
        var output = doAction(text);
        if (output == undefined)
            return;
        editor.edit(function (edit) {
            edit.replace(editor.selection, output);
        });
    });
    context.subscriptions.push(disposable);
}
exports.activate = activate;
// this method is called when your extension is deactivated
function deactivate() {
}
exports.deactivate = deactivate;
//# sourceMappingURL=json-organizer.js.map