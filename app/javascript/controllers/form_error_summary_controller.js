import { Controller } from "@hotwired/stimulus";
import { focusWhenVisible } from "utilities/focus";

export default class extends Controller {
  connect() {
    focusWhenVisible(this.element);
  }

  // Some inputs (e.g. datepicker v2, multi-checkbox attributes) don't have a 1:1
  // mapping between an ActiveModel attribute and a single DOM id. This helper
  // tries common conventions to find a focusable element for an error entry.
  resolveTarget(targetId) {
    if (!targetId) return null;

    const direct = document.getElementById(targetId);
    if (direct) return direct;

    // Datepicker v2 renders the actual input as "#{id}-input".
    const datepickerInput = document.getElementById(`${targetId}-input`);
    if (datepickerInput) return datepickerInput;

    // Multi-checkbox values typically render as "#{baseId}_<value>".
    const esc =
      window.CSS && typeof window.CSS.escape === "function"
        ? window.CSS.escape
        : (value) => String(value).replace(/[^a-zA-Z0-9_-]/g, "\\$&");

    const checkboxLike = document.querySelector(`[id^="${esc(targetId)}_"]`);
    if (checkboxLike) return checkboxLike;

    return null;
  }

  focusableElement(element) {
    if (!element) return null;

    // If it's already focusable, prefer it.
    if (typeof element.focus === "function" && element.tabIndex >= 0)
      return element;

    // Otherwise focus the first focusable descendant.
    const descendant = element.querySelector?.(
      'input, select, textarea, button, a[href], [tabindex]:not([tabindex="-1"])',
    );
    if (descendant) return descendant;

    // As a last resort, make it programmatically focusable.
    if (typeof element.focus === "function") {
      element.tabIndex = -1;
      return element;
    }

    return null;
  }

  focusField(event) {
    event.preventDefault();

    const targetId = event.params.targetId;
    const resolved = this.resolveTarget(targetId);
    const target = this.focusableElement(resolved);
    if (!target) return;

    focusWhenVisible(target);
    target.scrollIntoView({ block: "center", inline: "nearest" });
  }
}
