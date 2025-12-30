"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.test = test;
exports.testUri = testUri;
exports.escape = escape;
function test(input, regex) {
    // Reset before in case the regex has been invoked before
    regex.lastIndex = 0;
    const result = regex.test(input);
    // Allows re-using the regex in ase the regex contains g flag
    /** @see https://stackoverflow.com/a/1520853 */
    regex.lastIndex = 0;
    return result;
}
function testUri(input, regex) {
    // Match against string with Windows-style path separators normalized
    return test(input.replace(/\\/g, '/'), regex);
}
/** @see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions#Escaping */
function escape(string) {
    return string.replace(/[.*+\-?^${}()|[\]\\\/]/g, '\\$&'); // $& means the whole matched string
}
//# sourceMappingURL=regex.js.map