import assert from "node:assert/strict";
import test from "node:test";

import { focusMixin } from "../../app/javascript/controllers/virtual_scroll/focus.js";

// Create a mock controller context for testing
function createMockController(overrides = {}) {
  return {
    pendingFocusRow: null,
    pendingFocusCol: null,
    sortFocusToRestore: null,
    lifecycle: {
      listen: () => {},
      timeout: (fn) => {
        fn();
        return 1;
      },
    },
    element: {
      querySelector: () => null,
      contains: () => true,
    },
    bodyTarget: {
      querySelector: () => null,
    },
    keyboardNavigator: null,
    ...overrides,
    ...focusMixin,
  };
}

test("focusMixin provides expected methods", () => {
  assert.equal(
    typeof focusMixin.restorePendingFocusFromSessionStorage,
    "function",
  );
  assert.equal(typeof focusMixin.setupSortFocusRestoration, "function");
  assert.equal(typeof focusMixin.focusCellIfNeeded, "function");
  assert.equal(typeof focusMixin.rememberPendingFocusFromSortLink, "function");
  assert.equal(
    typeof focusMixin.rememberPendingFocusFromSortKeydown,
    "function",
  );
});

test("restorePendingFocusFromSessionStorage handles missing storage data", () => {
  const controller = createMockController();

  // Mock sessionStorage
  const originalSessionStorage = globalThis.sessionStorage;
  globalThis.sessionStorage = {
    getItem: () => null,
    removeItem: () => {},
  };

  try {
    // Should not throw
    controller.restorePendingFocusFromSessionStorage();
    assert.equal(controller.pendingFocusRow, null);
    assert.equal(controller.pendingFocusCol, null);
  } finally {
    globalThis.sessionStorage = originalSessionStorage;
  }
});

test("restorePendingFocusFromSessionStorage ignores expired data", () => {
  const controller = createMockController();

  const originalSessionStorage = globalThis.sessionStorage;
  globalThis.sessionStorage = {
    getItem: () =>
      JSON.stringify({
        path: "/test",
        ts: Date.now() - 10000, // 10 seconds ago (expired)
        row: 5,
        col: 3,
      }),
    removeItem: () => {},
  };

  const originalPathname = globalThis.window?.location?.pathname;
  globalThis.window = { location: { pathname: "/test" } };

  try {
    controller.restorePendingFocusFromSessionStorage();
    // Should not restore because TTL expired
    assert.equal(controller.pendingFocusRow, null);
    assert.equal(controller.pendingFocusCol, null);
  } finally {
    globalThis.sessionStorage = originalSessionStorage;
    if (originalPathname !== undefined) {
      globalThis.window.location.pathname = originalPathname;
    }
  }
});

test("restorePendingFocusFromSessionStorage ignores wrong path", () => {
  const controller = createMockController();

  const originalSessionStorage = globalThis.sessionStorage;
  globalThis.sessionStorage = {
    getItem: () =>
      JSON.stringify({
        path: "/other-page",
        ts: Date.now(),
        row: 5,
        col: 3,
      }),
    removeItem: () => {},
  };

  globalThis.window = { location: { pathname: "/test" } };

  try {
    controller.restorePendingFocusFromSessionStorage();
    // Should not restore because path doesn't match
    assert.equal(controller.pendingFocusRow, null);
    assert.equal(controller.pendingFocusCol, null);
  } finally {
    globalThis.sessionStorage = originalSessionStorage;
  }
});

test("restorePendingFocusFromSessionStorage restores valid data", () => {
  const controller = createMockController();

  let removedKey = null;
  const originalSessionStorage = globalThis.sessionStorage;
  globalThis.sessionStorage = {
    getItem: () =>
      JSON.stringify({
        path: "/test",
        ts: Date.now(),
        row: 5,
        col: 3,
      }),
    removeItem: (key) => {
      removedKey = key;
    },
  };

  globalThis.window = { location: { pathname: "/test" } };

  try {
    controller.restorePendingFocusFromSessionStorage();
    assert.equal(controller.pendingFocusRow, 5);
    assert.equal(controller.pendingFocusCol, 3);
    assert.equal(controller.sortFocusToRestore.row, 5);
    assert.equal(controller.sortFocusToRestore.col, 3);
    assert.equal(removedKey, "irida:virtual-scroll:pending-focus");
  } finally {
    globalThis.sessionStorage = originalSessionStorage;
  }
});

test("restorePendingFocusFromSessionStorage handles storage errors", () => {
  const controller = createMockController();

  const originalSessionStorage = globalThis.sessionStorage;
  globalThis.sessionStorage = {
    getItem: () => {
      throw new Error("Storage access denied");
    },
    removeItem: () => {},
  };

  try {
    // Should not throw
    controller.restorePendingFocusFromSessionStorage();
    assert.equal(controller.pendingFocusRow, null);
  } finally {
    globalThis.sessionStorage = originalSessionStorage;
  }
});

test("focusCellIfNeeded returns false when no cell found", () => {
  const controller = createMockController({
    element: {
      querySelector: () => ({
        querySelector: () => null, // No row found
      }),
    },
  });

  const result = controller.focusCellIfNeeded(1, 1);
  assert.equal(result, false);
});

test("focusCellIfNeeded returns false when bodyTarget is missing", () => {
  const controller = createMockController({
    element: {
      querySelector: () => null,
    },
    bodyTarget: null,
  });

  const result = controller.focusCellIfNeeded(1, 1);
  assert.equal(result, false);
});

test("rememberPendingFocusFromSortLink stores focus in sessionStorage", () => {
  const controller = createMockController();

  let storedData = null;
  const originalSessionStorage = globalThis.sessionStorage;
  globalThis.sessionStorage = {
    setItem: (key, value) => {
      storedData = { key, value: JSON.parse(value) };
    },
  };

  globalThis.window = { location: { pathname: "/samples" } };

  try {
    // Create mock link and header
    const mockLink = {
      closest: (selector) => {
        if (selector.includes("columnheader")) {
          return {
            getAttribute: (attr) => (attr === "aria-colindex" ? "5" : null),
          };
        }
        return null;
      },
    };

    controller.rememberPendingFocusFromSortLink(mockLink);

    assert.equal(storedData.key, "irida:virtual-scroll:pending-focus");
    assert.equal(storedData.value.path, "/samples");
    assert.equal(storedData.value.row, 1);
    assert.equal(storedData.value.col, 5);
    assert.ok(typeof storedData.value.ts === "number");
  } finally {
    globalThis.sessionStorage = originalSessionStorage;
  }
});

test("rememberPendingFocusFromSortLink does nothing when no header cell found", () => {
  const controller = createMockController();

  let called = false;
  const originalSessionStorage = globalThis.sessionStorage;
  globalThis.sessionStorage = {
    setItem: () => {
      called = true;
    },
  };

  try {
    const mockLink = {
      closest: () => null,
    };

    controller.rememberPendingFocusFromSortLink(mockLink);
    assert.equal(called, false);
  } finally {
    globalThis.sessionStorage = originalSessionStorage;
  }
});

test("rememberPendingFocusFromSortKeydown ignores non-activation keys", () => {
  const controller = createMockController();

  let called = false;
  const originalSessionStorage = globalThis.sessionStorage;
  globalThis.sessionStorage = {
    setItem: () => {
      called = true;
    },
  };

  try {
    // Tab key should be ignored
    controller.rememberPendingFocusFromSortKeydown({ key: "Tab" });
    assert.equal(called, false);

    // Escape key should be ignored
    controller.rememberPendingFocusFromSortKeydown({ key: "Escape" });
    assert.equal(called, false);

    // Arrow keys should be ignored
    controller.rememberPendingFocusFromSortKeydown({ key: "ArrowDown" });
    assert.equal(called, false);
  } finally {
    globalThis.sessionStorage = originalSessionStorage;
  }
});

test("setupSortFocusRestoration does nothing when no focus to restore", () => {
  const controller = createMockController({
    sortFocusToRestore: null,
  });

  // Should not throw and should not set up listeners
  let listenerAdded = false;
  controller.lifecycle = {
    listen: () => {
      listenerAdded = true;
    },
    timeout: () => {},
  };

  controller.setupSortFocusRestoration();
  assert.equal(listenerAdded, false);
});
