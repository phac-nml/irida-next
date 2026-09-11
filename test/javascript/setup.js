import { beforeEach, onTestFinished, vi } from "vitest";
import "@testing-library/jest-dom/vitest";

function ensureStorage(storageName) {
  const storage = window[storageName];
  if (storage && typeof storage.clear === "function") return;

  const values = new Map();

  Object.defineProperty(window, storageName, {
    configurable: true,
    value: {
      clear() {
        values.clear();
      },
      getItem(key) {
        return values.has(key) ? values.get(key) : null;
      },
      setItem(key, value) {
        values.set(key, String(value));
      },
      removeItem(key) {
        values.delete(key);
      },
      key(index) {
        return Array.from(values.keys())[index] ?? null;
      },
      get length() {
        return values.size;
      },
    },
  });
}

ensureStorage("localStorage");

// jsdom does not implement window.matchMedia
if (!window.matchMedia) {
  Object.defineProperty(window, "matchMedia", {
    writable: true,
    value: (query) => ({
      matches: false,
      media: query,
      onchange: null,
      addListener: () => {},
      removeListener: () => {},
      addEventListener: () => {},
      removeEventListener: () => {},
      dispatchEvent: () => false,
    }),
  });
}

// jsdom has no layout or scrolling implementation. Tests may spy on this shim.
if (!Element.prototype.scrollIntoView) {
  Element.prototype.scrollIntoView = () => {};
}

// Test-finished callbacks still run when a suite's afterEach throws.
beforeEach(() => {
  onTestFinished(async () => {
    document.body.replaceChildren();
    await Promise.resolve();
    await Promise.resolve();
    try {
      sessionStorage.clear();
      localStorage.clear();
    } finally {
      vi.unstubAllGlobals();
      vi.useRealTimers();
    }
  });
});
