// Virtual-scroll-specific lifecycle helper.
// Keeps connect/disconnect cleanup in one place without introducing app-wide abstractions.

export function createVirtualScrollLifecycle() {
  let stopped = false;
  const disposers = [];

  function add(disposer) {
    if (typeof disposer !== "function") return;

    if (stopped) {
      try {
        disposer();
      } catch {
        // ignore cleanup errors
      }
      return;
    }

    disposers.push(disposer);
  }

  function listen(target, eventName, handler, options) {
    if (!target?.addEventListener) return;

    target.addEventListener(eventName, handler, options);
    add(() => target.removeEventListener(eventName, handler, options));
  }

  function timeout(fn, ms) {
    const id = setTimeout(fn, ms);
    add(() => clearTimeout(id));
    return id;
  }

  function raf(fn) {
    const id = requestAnimationFrame(fn);
    add(() => cancelAnimationFrame(id));
    return id;
  }

  function trackObserver(observer) {
    if (!observer?.disconnect) return;
    add(() => observer.disconnect());
  }

  function trackDebounce(debouncedFn) {
    const cancel = debouncedFn?.cancel;
    if (typeof cancel !== "function") return;
    add(() => cancel.call(debouncedFn));
  }

  function stop() {
    if (stopped) return;
    stopped = true;

    for (let i = disposers.length - 1; i >= 0; i -= 1) {
      try {
        disposers[i]();
      } catch {
        // ignore cleanup errors
      }
    }

    disposers.length = 0;
  }

  return {
    add,
    listen,
    timeout,
    raf,
    trackObserver,
    trackDebounce,
    stop,
  };
}
