"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.notNullOrFalse = notNullOrFalse;
/**
 * Returns false if the value is null. Returns the value otherwise.
 */
function notNullOrFalse(value) {
    if (value == null) {
        return false;
    }
    return value;
}
//# sourceMappingURL=misc.js.map