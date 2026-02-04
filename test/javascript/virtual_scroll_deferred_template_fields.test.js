import assert from "node:assert/strict";
import test from "node:test";

// Mock Node constant for tests that don't have a DOM
if (typeof globalThis.Node === "undefined") {
  globalThis.Node = { ELEMENT_NODE: 1 };
}

import { deferredTemplateFieldsMixin } from "../../app/javascript/controllers/virtual_scroll/deferred_template_fields.js";

// Create a mock controller context for testing
function createMockController(overrides = {}) {
  return {
    hasTemplateContainerTarget: true,
    hasBodyTarget: true,
    templateContainerTarget: null,
    bodyTarget: null,
    deferredObserver: null,
    element: {
      isConnected: true,
      dispatchEvent: () => {},
    },
    lifecycle: {
      trackObserver: () => {},
      timeout: (fn) => {
        fn();
        return 1;
      },
    },
    ...overrides,
    ...deferredTemplateFieldsMixin,
  };
}

test("deferredTemplateFieldsMixin provides expected methods", () => {
  assert.equal(
    typeof deferredTemplateFieldsMixin.setupDeferredTemplateObserver,
    "function",
  );
  assert.equal(
    typeof deferredTemplateFieldsMixin.mergeDeferredTemplates,
    "function",
  );
  assert.equal(
    typeof deferredTemplateFieldsMixin.replaceVisiblePlaceholders,
    "function",
  );
});

test("setupDeferredTemplateObserver does nothing without template container", () => {
  const controller = createMockController({
    hasTemplateContainerTarget: false,
  });

  // Should not throw
  controller.setupDeferredTemplateObserver();
  assert.equal(controller.deferredObserver, null);
});

test("setupDeferredTemplateObserver creates MutationObserver", () => {
  let observedTarget = null;
  let observerOptions = null;
  let trackedObserver = null;

  const mockTemplateContainer = {
    querySelectorAll: () => [],
  };

  // Mock MutationObserver
  const OriginalMutationObserver = globalThis.MutationObserver;
  globalThis.MutationObserver = class MockMutationObserver {
    constructor(callback) {
      this.callback = callback;
    }
    observe(target, options) {
      observedTarget = target;
      observerOptions = options;
    }
    disconnect() {}
  };

  try {
    const controller = createMockController({
      templateContainerTarget: mockTemplateContainer,
      lifecycle: {
        trackObserver: (obs) => {
          trackedObserver = obs;
        },
        timeout: (fn) => {
          fn();
          return 1;
        },
      },
    });

    controller.setupDeferredTemplateObserver();

    assert.ok(controller.deferredObserver !== null);
    assert.equal(observedTarget, mockTemplateContainer);
    assert.deepEqual(observerOptions, { childList: true, subtree: false });
    assert.ok(trackedObserver !== null);
  } finally {
    globalThis.MutationObserver = OriginalMutationObserver;
  }
});

test("mergeDeferredTemplates does nothing without template container", () => {
  const controller = createMockController({
    hasTemplateContainerTarget: false,
  });

  // Should not throw
  controller.mergeDeferredTemplates();
});

test("mergeDeferredTemplates does nothing when no deferred containers found", () => {
  const controller = createMockController({
    templateContainerTarget: {
      querySelectorAll: () => [],
    },
  });

  // Should not throw
  controller.mergeDeferredTemplates();
});

test("mergeDeferredTemplates handles errors gracefully", () => {
  let dispatchedEvent = null;

  const controller = createMockController({
    templateContainerTarget: {
      querySelectorAll: () => {
        throw new Error("Query error");
      },
    },
    element: {
      isConnected: true,
      dispatchEvent: (event) => {
        dispatchedEvent = event;
      },
    },
  });

  // Should not throw
  controller.mergeDeferredTemplates();

  // Should dispatch error event
  assert.ok(dispatchedEvent !== null);
  assert.equal(dispatchedEvent.type, "virtual-scroll:error");
  assert.equal(dispatchedEvent.detail.context, "mergeDeferredTemplates");
});

test("replaceVisiblePlaceholders does nothing without body target", () => {
  const controller = createMockController({
    hasBodyTarget: false,
  });

  // Should not throw
  controller.replaceVisiblePlaceholders();
});

test("replaceVisiblePlaceholders does nothing when no placeholders found", () => {
  const controller = createMockController({
    bodyTarget: {
      querySelectorAll: () => [
        {
          dataset: { sampleId: "sample-1" },
          querySelectorAll: () => [], // No placeholders
        },
      ],
    },
  });

  // Should not throw
  controller.replaceVisiblePlaceholders();
});

test("MutationObserver callback handles deferred content detection", () => {
  let callbackFn = null;
  let mergeWasCalled = false;

  const mockTemplateContainer = {
    querySelectorAll: () => [],
  };

  // Mock MutationObserver
  const OriginalMutationObserver = globalThis.MutationObserver;
  globalThis.MutationObserver = class MockMutationObserver {
    constructor(callback) {
      callbackFn = callback;
    }
    observe() {}
    disconnect() {}
  };

  try {
    const controller = createMockController({
      templateContainerTarget: mockTemplateContainer,
      lifecycle: {
        trackObserver: () => {},
        timeout: (fn) => {
          fn();
          return 1;
        },
      },
    });

    // Override mergeDeferredTemplates to track if it was called
    controller.mergeDeferredTemplates = () => {
      mergeWasCalled = true;
    };

    controller.setupDeferredTemplateObserver();

    // Simulate mutation with deferred content
    const mockNode = {
      nodeType: 1, // Node.ELEMENT_NODE
      dataset: { deferred: "true" },
    };

    const mutations = [
      {
        addedNodes: [mockNode],
      },
    ];

    // Call the observer callback
    callbackFn(mutations);

    assert.equal(mergeWasCalled, true);
  } finally {
    globalThis.MutationObserver = OriginalMutationObserver;
  }
});

test("MutationObserver callback ignores non-deferred content", () => {
  let callbackFn = null;
  let mergeWasCalled = false;

  const mockTemplateContainer = {
    querySelectorAll: () => [],
  };

  // Mock MutationObserver
  const OriginalMutationObserver = globalThis.MutationObserver;
  globalThis.MutationObserver = class MockMutationObserver {
    constructor(callback) {
      callbackFn = callback;
    }
    observe() {}
    disconnect() {}
  };

  try {
    const controller = createMockController({
      templateContainerTarget: mockTemplateContainer,
      lifecycle: {
        trackObserver: () => {},
        timeout: (fn) => {
          fn();
          return 1;
        },
      },
    });

    // Override mergeDeferredTemplates to track if it was called
    controller.mergeDeferredTemplates = () => {
      mergeWasCalled = true;
    };

    controller.setupDeferredTemplateObserver();

    // Simulate mutation without deferred content
    const mockNode = {
      nodeType: 1, // Node.ELEMENT_NODE
      dataset: {}, // No deferred attribute
    };

    const mutations = [
      {
        addedNodes: [mockNode],
      },
    ];

    // Call the observer callback
    callbackFn(mutations);

    assert.equal(mergeWasCalled, false);
  } finally {
    globalThis.MutationObserver = OriginalMutationObserver;
  }
});

test("MutationObserver callback guards against disconnected controller", () => {
  let callbackFn = null;
  let mergeWasCalled = false;

  const mockTemplateContainer = {
    querySelectorAll: () => [],
  };

  // Mock MutationObserver
  const OriginalMutationObserver = globalThis.MutationObserver;
  globalThis.MutationObserver = class MockMutationObserver {
    constructor(callback) {
      callbackFn = callback;
    }
    observe() {}
    disconnect() {}
  };

  try {
    const controller = createMockController({
      templateContainerTarget: mockTemplateContainer,
      element: {
        isConnected: false, // Controller disconnected
      },
      lifecycle: {
        trackObserver: () => {},
        timeout: (fn) => {
          fn();
          return 1;
        },
      },
    });

    // Override mergeDeferredTemplates to track if it was called
    controller.mergeDeferredTemplates = () => {
      mergeWasCalled = true;
    };

    controller.setupDeferredTemplateObserver();

    // Simulate mutation with deferred content
    const mockNode = {
      nodeType: 1,
      dataset: { deferred: "true" },
    };

    const mutations = [
      {
        addedNodes: [mockNode],
      },
    ];

    // Call the observer callback
    callbackFn(mutations);

    // Should not call merge because controller is disconnected
    assert.equal(mergeWasCalled, false);
  } finally {
    globalThis.MutationObserver = OriginalMutationObserver;
  }
});
