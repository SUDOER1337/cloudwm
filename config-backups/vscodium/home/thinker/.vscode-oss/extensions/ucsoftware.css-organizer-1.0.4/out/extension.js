"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.deactivate = exports.activate = void 0;
const css_organizer_1 = require("./css-organizer");
let cssOrganizer;
function activate(context) {
    cssOrganizer = new css_organizer_1.CssOrganizer(context);
    cssOrganizer.registerCmd('css-organizer.alphabetically', () => {
        cssOrganizer.organizeAlphabetically();
    });
    cssOrganizer.registerCmd('css-organizer.grouped', () => {
        cssOrganizer.organizeGrouped();
    });
    cssOrganizer.loadGroupSorters(context);
}
exports.activate = activate;
// this method is called when your extension is deactivated
function deactivate() { }
exports.deactivate = deactivate;
//# sourceMappingURL=extension.js.map