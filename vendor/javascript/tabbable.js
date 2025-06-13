// tabbable@6.2.0 downloaded from https://ga.jspm.io/npm:tabbable@6.2.0/dist/index.esm.js

/*!
* tabbable 6.2.0
* @license MIT, https://github.com/focus-trap/tabbable/blob/master/LICENSE
*/
var e=["input:not([inert])","select:not([inert])","textarea:not([inert])","a[href]:not([inert])","button:not([inert])","[tabindex]:not(slot):not([inert])","audio[controls]:not([inert])","video[controls]:not([inert])",'[contenteditable]:not([contenteditable="false"]):not([inert])',"details>summary:first-of-type:not([inert])","details:not([inert])"];var t=e.join(",");var n="undefined"===typeof Element;var r=n?function(){}:Element.prototype.matches||Element.prototype.msMatchesSelector||Element.prototype.webkitMatchesSelector;var a=!n&&Element.prototype.getRootNode?function(e){var t;return null===e||void 0===e||null===(t=e.getRootNode)||void 0===t?void 0:t.call(e)}:function(e){return null===e||void 0===e?void 0:e.ownerDocument};
/**
 * Determines if a node is inert or in an inert ancestor.
 * @param {Element} [node]
 * @param {boolean} [lookUp] If true and `node` is not inert, looks up at ancestors to
 *  see if any of them are inert. If false, only `node` itself is considered.
 * @returns {boolean} True if inert itself or by way of being in an inert ancestor.
 *  False if `node` is falsy.
 */var o=function isInert(e,t){var n;void 0===t&&(t=true);var r=null===e||void 0===e||null===(n=e.getAttribute)||void 0===n?void 0:n.call(e,"inert");var a=""===r||"true"===r;var o=a||t&&e&&isInert(e.parentNode);return o};
/**
 * Determines if a node's content is editable.
 * @param {Element} [node]
 * @returns True if it's content-editable; false if it's not or `node` is falsy.
 */var i=function isContentEditable(e){var t;var n=null===e||void 0===e||null===(t=e.getAttribute)||void 0===t?void 0:t.call(e,"contenteditable");return""===n||"true"===n};
/**
 * @param {Element} el container to check in
 * @param {boolean} includeContainer add container to check
 * @param {(node: Element) => boolean} filter filter candidates
 * @returns {Element[]}
 */var l=function getCandidates(e,n,a){if(o(e))return[];var i=Array.prototype.slice.apply(e.querySelectorAll(t));n&&r.call(e,t)&&i.unshift(e);i=i.filter(a);return i};
/**
 * @callback GetShadowRoot
 * @param {Element} element to check for shadow root
 * @returns {ShadowRoot|boolean} ShadowRoot if available or boolean indicating if a shadowRoot is attached but not available.
 */
/**
 * @callback ShadowRootFilter
 * @param {Element} shadowHostNode the element which contains shadow content
 * @returns {boolean} true if a shadow root could potentially contain valid candidates.
 */
/**
 * @typedef {Object} CandidateScope
 * @property {Element} scopeParent contains inner candidates
 * @property {Element[]} candidates list of candidates found in the scope parent
 */
/**
 * @typedef {Object} IterativeOptions
 * @property {GetShadowRoot|boolean} getShadowRoot true if shadow support is enabled; falsy if not;
 *  if a function, implies shadow support is enabled and either returns the shadow root of an element
 *  or a boolean stating if it has an undisclosed shadow root
 * @property {(node: Element) => boolean} filter filter candidates
 * @property {boolean} flatten if true then result will flatten any CandidateScope into the returned list
 * @property {ShadowRootFilter} shadowRootFilter filter shadow roots;
 */
/**
 * @param {Element[]} elements list of element containers to match candidates from
 * @param {boolean} includeContainer add container list to check
 * @param {IterativeOptions} options
 * @returns {Array.<Element|CandidateScope>}
 */var u=function getCandidatesIteratively(e,n,a){var i=[];var l=Array.from(e);while(l.length){var u=l.shift();if(!o(u,false))if("SLOT"===u.tagName){var d=u.assignedElements();var s=d.length?d:u.children;var c=getCandidatesIteratively(s,true,a);a.flatten?i.push.apply(i,c):i.push({scopeParent:u,candidates:c})}else{var v=r.call(u,t);v&&a.filter(u)&&(n||!e.includes(u))&&i.push(u);var f=u.shadowRoot||"function"===typeof a.getShadowRoot&&a.getShadowRoot(u);var p=!o(f,false)&&(!a.shadowRootFilter||a.shadowRootFilter(u));if(f&&p){var h=getCandidatesIteratively(true===f?u.children:f.children,true,a);a.flatten?i.push.apply(i,h):i.push({scopeParent:u,candidates:h})}else l.unshift.apply(l,u.children)}}return i};
/**
 * @private
 * Determines if the node has an explicitly specified `tabindex` attribute.
 * @param {HTMLElement} node
 * @returns {boolean} True if so; false if not.
 */var d=function hasTabIndex(e){return!isNaN(parseInt(e.getAttribute("tabindex"),10))};
/**
 * Determine the tab index of a given node.
 * @param {HTMLElement} node
 * @returns {number} Tab order (negative, 0, or positive number).
 * @throws {Error} If `node` is falsy.
 */var s=function getTabIndex(e){if(!e)throw new Error("No node provided");return e.tabIndex<0&&(/^(AUDIO|VIDEO|DETAILS)$/.test(e.tagName)||i(e))&&!d(e)?0:e.tabIndex};
/**
 * Determine the tab index of a given node __for sort order purposes__.
 * @param {HTMLElement} node
 * @param {boolean} [isScope] True for a custom element with shadow root or slot that, by default,
 *  has tabIndex -1, but needs to be sorted by document order in order for its content to be
 *  inserted into the correct sort position.
 * @returns {number} Tab order (negative, 0, or positive number).
 */var c=function getSortOrderTabIndex(e,t){var n=s(e);return n<0&&t&&!d(e)?0:n};var v=function sortOrderedTabbables(e,t){return e.tabIndex===t.tabIndex?e.documentOrder-t.documentOrder:e.tabIndex-t.tabIndex};var f=function isInput(e){return"INPUT"===e.tagName};var p=function isHiddenInput(e){return f(e)&&"hidden"===e.type};var h=function isDetailsWithSummary(e){var t="DETAILS"===e.tagName&&Array.prototype.slice.apply(e.children).some((function(e){return"SUMMARY"===e.tagName}));return t};var b=function getCheckedRadio(e,t){for(var n=0;n<e.length;n++)if(e[n].checked&&e[n].form===t)return e[n]};var m=function isTabbableRadio(e){if(!e.name)return true;var t=e.form||a(e);var n=function queryRadios(e){return t.querySelectorAll('input[type="radio"][name="'+e+'"]')};var r;if("undefined"!==typeof window&&"undefined"!==typeof window.CSS&&"function"===typeof window.CSS.escape)r=n(window.CSS.escape(e.name));else try{r=n(e.name)}catch(e){console.error("Looks like you have a radio button with a name attribute containing invalid CSS selector characters and need the CSS.escape polyfill: %s",e.message);return false}var o=b(r,e.form);return!o||o===e};var g=function isRadio(e){return f(e)&&"radio"===e.type};var y=function isNonTabbableRadio(e){return g(e)&&!m(e)};var w=function isNodeAttached(e){var t;var n=e&&a(e);var r=null===(t=n)||void 0===t?void 0:t.host;var o=false;if(n&&n!==e){var i,l,u;o=!!(null!==(i=r)&&void 0!==i&&null!==(l=i.ownerDocument)&&void 0!==l&&l.contains(r)||null!==e&&void 0!==e&&null!==(u=e.ownerDocument)&&void 0!==u&&u.contains(e));while(!o&&r){var d,s,c;n=a(r);r=null===(d=n)||void 0===d?void 0:d.host;o=!!(null!==(s=r)&&void 0!==s&&null!==(c=s.ownerDocument)&&void 0!==c&&c.contains(r))}}return o};var S=function isZeroArea(e){var t=e.getBoundingClientRect(),n=t.width,r=t.height;return 0===n&&0===r};var E=function isHidden(e,t){var n=t.displayCheck,o=t.getShadowRoot;if("hidden"===getComputedStyle(e).visibility)return true;var i=r.call(e,"details>summary:first-of-type");var l=i?e.parentElement:e;if(r.call(l,"details:not([open]) *"))return true;if(n&&"full"!==n&&"legacy-full"!==n){if("non-zero-area"===n)return S(e)}else{if("function"===typeof o){var u=e;while(e){var d=e.parentElement;var s=a(e);if(d&&!d.shadowRoot&&true===o(d))return S(e);e=e.assignedSlot?e.assignedSlot:d||s===e.ownerDocument?d:s.host}e=u}if(w(e))return!e.getClientRects().length;if("legacy-full"!==n)return true}return false};var I=function isDisabledFromFieldset(e){if(/^(INPUT|BUTTON|SELECT|TEXTAREA)$/.test(e.tagName)){var t=e.parentElement;while(t){if("FIELDSET"===t.tagName&&t.disabled){for(var n=0;n<t.children.length;n++){var a=t.children.item(n);if("LEGEND"===a.tagName)return!!r.call(t,"fieldset[disabled] *")||!a.contains(e)}return true}t=t.parentElement}}return false};var N=function isNodeMatchingSelectorFocusable(e,t){return!(t.disabled||o(t)||p(t)||E(t,e)||h(t)||I(t))};var R=function isNodeMatchingSelectorTabbable(e,t){return!(y(t)||s(t)<0||!N(e,t))};var C=function isValidShadowRootTabbable(e){var t=parseInt(e.getAttribute("tabindex"),10);return!!(isNaN(t)||t>=0)};
/**
 * @param {Array.<Element|CandidateScope>} candidates
 * @returns Element[]
 */var T=function sortByOrder(e){var t=[];var n=[];e.forEach((function(e,r){var a=!!e.scopeParent;var o=a?e.scopeParent:e;var i=c(o,a);var l=a?sortByOrder(e.candidates):o;0===i?a?t.push.apply(t,l):t.push(o):n.push({documentOrder:r,tabIndex:i,item:e,isScope:a,content:l})}));return n.sort(v).reduce((function(e,t){t.isScope?e.push.apply(e,t.content):e.push(t.content);return e}),[]).concat(t)};var A=function tabbable(e,t){t=t||{};var n;n=t.getShadowRoot?u([e],t.includeContainer,{filter:R.bind(null,t),flatten:false,getShadowRoot:t.getShadowRoot,shadowRootFilter:C}):l(e,t.includeContainer,R.bind(null,t));return T(n)};var x=function focusable(e,t){t=t||{};var n;n=t.getShadowRoot?u([e],t.includeContainer,{filter:N.bind(null,t),flatten:true,getShadowRoot:t.getShadowRoot}):l(e,t.includeContainer,N.bind(null,t));return n};var D=function isTabbable(e,n){n=n||{};if(!e)throw new Error("No node provided");return false!==r.call(e,t)&&R(n,e)};var O=e.concat("iframe").join(",");var F=function isFocusable(e,t){t=t||{};if(!e)throw new Error("No node provided");return false!==r.call(e,O)&&N(t,e)};export{x as focusable,s as getTabIndex,F as isFocusable,D as isTabbable,A as tabbable};

