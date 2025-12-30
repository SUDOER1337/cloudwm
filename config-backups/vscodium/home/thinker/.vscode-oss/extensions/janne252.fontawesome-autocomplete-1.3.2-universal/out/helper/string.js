"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setCharacterCase = setCharacterCase;
/**
 * Sets the character case in the specified index.
 */
function setCharacterCase(str, index, characterCase) {
    let char = '';
    if (index < str.length) {
        switch (characterCase) {
            case 'upper':
                char = str[index].toUpperCase();
                break;
            case 'lower':
                char = str[index].toLowerCase();
                break;
        }
    }
    return `${char}${str.substring(index + 1)}`;
}
//# sourceMappingURL=string.js.map