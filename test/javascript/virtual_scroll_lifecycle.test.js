import assert from "node:assert/strict";
import test from "node:test";

import { createVirtualScrollLifecycle } from "../../app/javascript/controllers/virtual_scroll/lifecycle.js";

test("createVirtualScrollLifecycle returns lifecycle object with expected methods", () => {
  const lifecycle = createVirtualScrollLifecycle();

  assert.equal(typeof lifecycle.add, "function");
  assert.equal(typeof lifecycle.listen, "function");
  assert.equal(typeof lifecycle.timeout, "function");
  assert.equal(typeof lifecycle.raf, "function");
  assert.equal(typeof lifecycle.trackObserver, "function");
  assert.equal(typeof lifecycle.trackDebounce, "function");
  assert.equal(typeof lifecycle.stop, "function");
});

test("add() executes disposer immediately if already stopped", () => {
  const lifecycle = createVirtualScrollLifecycle();
  lifecycle.stop();

  let called = false;
  lifecycle.add(() => {
    called = true;
  });

  assert.equal(called, true);
});

test("add() defers disposer execution until stop() is called", () => {
  const lifecycle = createVirtualScrollLifecycle();

  let called = false;
  lifecycle.add(() => {
    called = true;
  });

  assert.equal(called, false);
  lifecycle.stop();
  assert.equal(called, true);
});

test("add() ignores non-function arguments", () => {
  const lifecycle = createVirtualScrollLifecycle();

  // Should not throw
  lifecycle.add(null);
  lifecycle.add(undefined);
  lifecycle.add("string");
  lifecycle.add(123);

  lifecycle.stop();
});

test("stop() executes disposers in reverse order", () => {
  const lifecycle = createVirtualScrollLifecycle();
  const order = [];

  lifecycle.add(() => order.push(1));
  lifecycle.add(() => order.push(2));
  lifecycle.add(() => order.push(3));

  lifecycle.stop();

  assert.deepEqual(order, [3, 2, 1]);
});

test("stop() can be called multiple times safely", () => {
  const lifecycle = createVirtualScrollLifecycle();

  let count = 0;
  lifecycle.add(() => {
    count++;
  });

  lifecycle.stop();
  lifecycle.stop();
  lifecycle.stop();

  assert.equal(count, 1);
});

test("stop() ignores errors in disposers", () => {
  const lifecycle = createVirtualScrollLifecycle();

  let secondCalled = false;
  lifecycle.add(() => {
    throw new Error("First disposer error");
  });
  lifecycle.add(() => {
    secondCalled = true;
  });

  // Should not throw
  lifecycle.stop();

  // Second disposer should still be called (runs first due to reverse order)
  assert.equal(secondCalled, true);
});

test("listen() adds and removes event listener", () => {
  const lifecycle = createVirtualScrollLifecycle();

  const target = {
    listeners: [],
    addEventListener(event, handler, options) {
      this.listeners.push({ event, handler, options });
    },
    removeEventListener(event, handler) {
      this.listeners = this.listeners.filter(
        (l) => l.event !== event || l.handler !== handler,
      );
    },
  };

  const handler = () => {};
  lifecycle.listen(target, "click", handler, { capture: true });

  assert.equal(target.listeners.length, 1);
  assert.equal(target.listeners[0].event, "click");

  lifecycle.stop();

  assert.equal(target.listeners.length, 0);
});

test("listen() handles null target gracefully", () => {
  const lifecycle = createVirtualScrollLifecycle();

  // Should not throw
  lifecycle.listen(null, "click", () => {});
  lifecycle.listen(undefined, "click", () => {});

  lifecycle.stop();
});

test("trackObserver() disconnects observer on stop", () => {
  const lifecycle = createVirtualScrollLifecycle();

  let disconnected = false;
  const observer = {
    disconnect() {
      disconnected = true;
    },
  };

  lifecycle.trackObserver(observer);

  assert.equal(disconnected, false);
  lifecycle.stop();
  assert.equal(disconnected, true);
});

test("trackObserver() handles null observer gracefully", () => {
  const lifecycle = createVirtualScrollLifecycle();

  // Should not throw
  lifecycle.trackObserver(null);
  lifecycle.trackObserver(undefined);
  lifecycle.trackObserver({});

  lifecycle.stop();
});

test("trackDebounce() clears debounced function on stop", () => {
  const lifecycle = createVirtualScrollLifecycle();

  let cleared = false;
  const debouncedFn = () => {};
  debouncedFn.clear = () => {
    cleared = true;
  };

  lifecycle.trackDebounce(debouncedFn);

  assert.equal(cleared, false);
  lifecycle.stop();
  assert.equal(cleared, true);
});

test("trackDebounce() handles functions without clear gracefully", () => {
  const lifecycle = createVirtualScrollLifecycle();

  // Should not throw
  lifecycle.trackDebounce(() => {});
  lifecycle.trackDebounce(null);

  lifecycle.stop();
});

test("timeout() returns timeout ID and clears on stop", () => {
  const lifecycle = createVirtualScrollLifecycle();

  // Mock setTimeout/clearTimeout
  const originalSetTimeout = globalThis.setTimeout;
  const originalClearTimeout = globalThis.clearTimeout;

  let clearedId = null;
  globalThis.setTimeout = () => 42; // Return fake ID
  globalThis.clearTimeout = (id) => {
    clearedId = id;
  };

  try {
    const id = lifecycle.timeout(() => {}, 100);
    assert.equal(id, 42);

    lifecycle.stop();
    assert.equal(clearedId, 42);
  } finally {
    globalThis.setTimeout = originalSetTimeout;
    globalThis.clearTimeout = originalClearTimeout;
  }
});

test("raf() returns RAF ID and cancels on stop", () => {
  const lifecycle = createVirtualScrollLifecycle();

  // Mock requestAnimationFrame/cancelAnimationFrame
  const originalRAF = globalThis.requestAnimationFrame;
  const originalCancel = globalThis.cancelAnimationFrame;

  let cancelledId = null;
  globalThis.requestAnimationFrame = () => 99; // Return fake ID
  globalThis.cancelAnimationFrame = (id) => {
    cancelledId = id;
  };

  try {
    const id = lifecycle.raf(() => {});
    assert.equal(id, 99);

    lifecycle.stop();
    assert.equal(cancelledId, 99);
  } finally {
    globalThis.requestAnimationFrame = originalRAF;
    globalThis.cancelAnimationFrame = originalCancel;
  }
});
