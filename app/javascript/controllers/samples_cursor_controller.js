import { Controller } from "@hotwired/stimulus";

// Sorting replaces only this frame. The old grid disconnects and cancels its row requests.
export default class extends Controller {
  static values = { statusId: String };

  disconnect() {
    if (this.restoreFrame) cancelAnimationFrame(this.restoreFrame);
    this.queryRequest?.abort();
  }

  sort(event) {
    const button = event.currentTarget;
    if (this.restoreFrame) cancelAnimationFrame(this.restoreFrame);
    this.requestedUrl = this.normalizedUrl(button.dataset.sortUrl);
    this.sortField = button.dataset.sortField;
    this.scrollLeft = this.scrollContainer?.scrollLeft || 0;
    this.element.src = button.dataset.sortUrl;
  }

  // Turbo frame visits and form submissions use separate request lanes. Coordinate
  // every result-changing request here, including forms in the metadata frame.
  request(event) {
    if (event.target !== this.element && event.target.tagName !== "FORM")
      return;
    this.queryRequest?.abort();
    this.queryRequest = new AbortController();
    this.requestId = crypto.randomUUID();
    const { fetchOptions, url } = event.detail;
    fetchOptions.headers["X-Samples-Cursor-Request"] = this.requestId;
    fetchOptions.signal = AbortSignal.any([
      fetchOptions.signal,
      this.queryRequest.signal,
    ]);
    if (
      event.target === this.element &&
      this.normalizedUrl(url) === this.requestedUrl
    ) {
      this.sortRequestId = this.requestId;
    } else {
      this.sortField = null;
      this.requestedUrl = null;
      if (this.restoreFrame) cancelAnimationFrame(this.restoreFrame);
    }
  }

  renderFrame(event) {
    if (event.target !== this.element) return;
    const requestId = event.detail.newFrame.dataset.cursorRequestId;
    const render = event.detail.render;
    event.detail.render = (...args) => {
      if (requestId !== this.requestId) return;
      this.acceptedRequestId = requestId;
      return render(...args);
    };
  }

  renderStream(event) {
    const stream = event.target;
    const requestId = stream.dataset.cursorRequestId;
    if (
      !requestId ||
      ![this.element.id, "table-filter"].includes(stream.getAttribute("target"))
    )
      return;
    const render = event.detail.render;
    event.detail.render = (...args) => {
      if (requestId === this.requestId) return render(...args);
    };
  }

  restore(event) {
    if (
      event.target !== this.element ||
      !this.sortField ||
      this.acceptedRequestId !== this.sortRequestId
    )
      return;
    const result = this.element.querySelector("[data-cursor-refresh-url]");
    if (
      !result?.dataset.cursorRefreshUrl ||
      this.normalizedUrl(result.dataset.cursorRefreshUrl) !== this.requestedUrl
    )
      return;
    this.requestedUrl = null;
    const status =
      this.hasStatusIdValue && document.getElementById(this.statusIdValue);
    if (status && result.dataset.cursorSortMessage)
      status.textContent = result.dataset.cursorSortMessage;

    const focused = document.activeElement;
    if (focused !== document.body && !this.element.contains(focused)) {
      this.sortField = null;
      return;
    }
    this.restoreFrame = requestAnimationFrame(() => {
      this.restoreFrame = null;
      if (this.scrollContainer) {
        this.scrollContainer.scrollLeft = this.scrollLeft;
        this.scrollContainer.dispatchEvent(new Event("scroll"));
      }
      // Horizontal virtualization renders its new column window on the next frame.
      this.restoreFrame = requestAnimationFrame(() => {
        this.restoreFrame = null;
        const button = Array.from(
          this.element.querySelectorAll("[data-sort-field]"),
        ).find((candidate) => candidate.dataset.sortField === this.sortField);
        const active = document.activeElement;
        if (active === document.body || this.element.contains(active)) {
          button?.focus({ preventScroll: true });
        }
        this.sortField = null;
      });
    });
  }

  normalizedUrl(value) {
    const url = new URL(value, document.baseURI);
    url.searchParams.sort();
    return url.href;
  }

  get scrollContainer() {
    return this.element.querySelector(
      '[data-pathogen--data-grid-target~="scrollContainer"]',
    );
  }
}
