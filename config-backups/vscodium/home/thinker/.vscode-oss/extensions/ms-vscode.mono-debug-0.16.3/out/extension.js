/*---------------------------------------------------------
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------*/
'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
exports.deactivate = exports.activate = void 0;
const vscode = require("vscode");
const nls = require("vscode-nls");
const localize = nls.config()();
const configuration = vscode.workspace.getConfiguration('mono-debug');
function activate(context) {
    context.subscriptions.push(vscode.commands.registerCommand('extension.mono-debug.configureExceptions', () => configureExceptions()));
    context.subscriptions.push(vscode.commands.registerCommand('extension.mono-debug.startSession', config => startSession(config)));
}
exports.activate = activate;
function deactivate() {
    // do nothing.
}
exports.deactivate = deactivate;
// if the user has not configured anything, we populate the exception configurationwith these defaults
const DEFAULT_EXCEPTIONS = {
    "System.Exception": "never",
    "System.SystemException": "never",
    "System.ArithmeticException": "never",
    "System.ArrayTypeMismatchException": "never",
    "System.DivideByZeroException": "never",
    "System.IndexOutOfRangeException": "never",
    "System.InvalidCastException": "never",
    "System.NullReferenceException": "never",
    "System.OutOfMemoryException": "never",
    "System.OverflowException": "never",
    "System.StackOverflowException": "never",
    "System.TypeInitializationException": "never"
};
class BreakOptionItem {
}
// the possible exception options converted into QuickPickItem
const OPTIONS = ['never', 'always', 'unhandled'].map((bm) => {
    const breakMode = bm;
    return {
        label: translate(breakMode),
        description: '',
        breakMode: breakMode
    };
});
class ExceptionItem {
}
function translate(mode) {
    switch (mode) {
        case 'never':
            return localize('breakmode.never', "Never break");
        case 'always':
            return localize('breakmode.always', "Always break");
        case 'unhandled':
            return localize('breakmode.unhandled', "Break when unhandled");
        default:
            return mode;
    }
}
function getModel() {
    let model = DEFAULT_EXCEPTIONS;
    if (configuration) {
        const exceptionOptions = configuration.get('exceptionOptions');
        if (exceptionOptions) {
            model = exceptionOptions;
        }
    }
    return model;
}
function configureExceptions() {
    const options = {
        placeHolder: localize('select.exception', "First Select Exception"),
        matchOnDescription: true,
        matchOnDetail: true
    };
    const exceptionItems = [];
    const model = getModel();
    for (const exception in model) {
        exceptionItems.push({
            label: exception,
            description: model[exception] !== 'never' ? `⚡ ${translate(model[exception])}` : ''
        });
    }
    vscode.window.showQuickPick(exceptionItems, options).then(exceptionItem => {
        if (exceptionItem) {
            const options = {
                placeHolder: localize('select.break.option', "Then Select Break Option"),
                matchOnDescription: true,
                matchOnDetail: true
            };
            vscode.window.showQuickPick(OPTIONS, options).then(item => {
                if (item) {
                    model[exceptionItem.label] = item.breakMode;
                    if (configuration) {
                        configuration.update('exceptionOptions', model);
                    }
                    setExceptionBreakpoints(model);
                }
            });
        }
    });
}
function setExceptionBreakpoints(model) {
    const args = {
        filters: [],
        exceptionOptions: convertToExceptionOptions(model)
    };
    if (vscode.debug.activeDebugSession)
        vscode.debug.activeDebugSession.customRequest('setExceptionBreakpoints', args);
}
function convertToExceptionOptions(model) {
    const exceptionItems = [];
    for (const exception in model) {
        exceptionItems.push({
            path: [{ names: [exception] }],
            breakMode: model[exception]
        });
    }
    return exceptionItems;
}
//----- configureExceptions ---------------------------------------------------------------------------------------------------
/**
 * The result type of the startSession command.
 */
class StartSessionResult {
}
function startSession(config) {
    if (config && !config.__exceptionOptions) {
        config.__exceptionOptions = convertToExceptionOptions(getModel());
    }
    vscode.commands.executeCommand('vscode.startDebug', config);
    return {
        status: 'ok'
    };
}
//# sourceMappingURL=extension.js.map