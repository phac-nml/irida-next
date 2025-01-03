// escape-string-regexp@5.0.0 downloaded from https://ga.jspm.io/npm:escape-string-regexp@5.0.0/index.js

function escapeStringRegexp(e){if("string"!==typeof e)throw new TypeError("Expected a string");return e.replace(/[|\\{}()[\]^$+*?.]/g,"\\$&").replace(/-/g,"\\x2d")}export default escapeStringRegexp;

