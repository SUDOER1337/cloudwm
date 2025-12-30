"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.capability = void 0;
const semver = require("semver");
function capability(capabilities, key, supportedVersion) {
    const capability = capabilities[key];
    if (capability === undefined) {
        return undefined;
    }
    if (!semver.satisfies(capability.version, supportedVersion)) {
        return undefined;
    }
    return capability;
}
exports.capability = capability;
//# sourceMappingURL=capabilities.js.map