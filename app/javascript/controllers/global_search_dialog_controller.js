import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";
import { announce } from "utilities/live_region";

const EDITABLE_SELECTOR =
  "input, textarea, select, [contenteditable]:not([contenteditable='false'])";

// Matches the Tailwind `md` breakpoint (768px). Update if tailwind.config changes.
const MOBILE_BREAKPOINT_QUERY = "(max-width: 767px)";

export default class extends Controller {
  static targets = [
    "dialog",
    "backdrop",
    "trigger",
    "mobileTrigger",
    "form",
    "queryInput",
    "filtersDetails",
    "filtersContent",
  ];

  static values = {
    path: String,
    openedAnnouncement: String,
    closedAnnouncement: String,
  };

  connect() {
    this.previouslyFocusedElement = null;
    this.syncFilters();
    this.#syncTriggerState(false);
  }

  disconnect() {
    this.previouslyFocusedElement = null;
  }

  filtersDetailsTargetConnected() {
    this.syncFilters();
  }

  filtersContentTargetConnected() {
    this.syncFilters();
  }

  syncFilters() {
    if (!this.hasFiltersDetailsTarget || !this.hasFiltersContentTarget) {
      return;
    }

    const isExpanded = this.filtersDetailsTarget.open;
    this.filtersContentTarget.hidden = !isExpanded;

    if ("inert" in this.filtersContentTarget) {
      this.filtersContentTarget.inert = !isExpanded;
    }
  }

  handle(event) {
    if (event.key === "Escape" && this.#isOpen()) {
      event.preventDefault();
      this.close();
      return;
    }

    if (
      event.defaultPrevented ||
      event.isComposing ||
      event.repeat ||
      this.#isEditableTarget(event.target)
    ) {
      return;
    }

    if (!this.#isOpenShortcut(event) && !this.#isSlashShortcut(event)) {
      return;
    }

    if (this.#hasBlockingModal()) {
      return;
    }

    event.preventDefault();
    this.openPanel();
  }

  handleOutsideClick(event) {
    if (!this.#isOpen() || this.#isMobileViewport()) {
      return;
    }

    if (this.element.contains(event.target)) {
      return;
    }

    this.close();
  }

  openFromTrigger(event) {
    event.preventDefault();
    this.openPanel();
  }

  openPanel() {
    if (!this.hasDialogTarget) {
      this.#visitSearchPage();
      return;
    }

    if (this.#isOpen()) {
      this.#focusSearchInput();
      return;
    }

    this.#rememberFocusedElement();
    this.dialogTarget.hidden = false;

    if (this.#isMobileViewport()) {
      this.backdropTarget.hidden = false;
      document.body.classList.add("overflow-hidden");
    } else {
      this.backdropTarget.hidden = true;
    }

    this.#syncTriggerState(true);
    this.#announceOpened();
    this.#focusSearchInput();
  }

  close() {
    this.#closeAndClear();
  }

  handleSubmit() {
    if (!this.#isOpen()) {
      return;
    }

    this.dialogTarget.hidden = true;
    this.backdropTarget.hidden = true;
    document.body.classList.remove("overflow-hidden");
    this.#syncTriggerState(false);
    this.#restoreFocus();
  }

  #isOpenShortcut(event) {
    return (
      (event.metaKey || event.ctrlKey) &&
      !event.altKey &&
      !event.shiftKey &&
      event.key.toLowerCase() === "k"
    );
  }

  #isSlashShortcut(event) {
    return (
      !event.metaKey &&
      !event.ctrlKey &&
      !event.altKey &&
      (event.key === "/" || event.code === "NumpadDivide")
    );
  }

  #closeAndClear() {
    this.#resetForm();

    if (!this.#isOpen()) {
      return;
    }

    this.dialogTarget.hidden = true;
    this.backdropTarget.hidden = true;
    document.body.classList.remove("overflow-hidden");
    this.#syncTriggerState(false);
    this.#announceClosed();
    this.#restoreFocus();
  }

  #isOpen() {
    return this.hasDialogTarget && !this.dialogTarget.hidden;
  }

  #visitSearchPage() {
    if (!this.hasPathValue || !this.pathValue) {
      console.error(
        "Global search dialog fallback navigation is not configured: missing `pathValue`.",
      );
      return;
    }

    try {
      Turbo.visit(this.pathValue);
    } catch (error) {
      console.error("Failed to navigate to global search page.", error);
    }
  }

  #announceOpened() {
    if (this.hasOpenedAnnouncementValue) {
      announce(this.openedAnnouncementValue);
    }
  }

  #announceClosed() {
    if (this.hasClosedAnnouncementValue) {
      announce(this.closedAnnouncementValue);
    }
  }

  #resetForm() {
    if (!this.hasFormTarget) {
      return;
    }

    this.formTarget.reset();

    this.formTarget.querySelectorAll("details").forEach((detailsElement) => {
      detailsElement.open = false;
    });

    this.syncFilters();
  }

  #focusSearchInput() {
    if (!this.hasQueryInputTarget) {
      return;
    }

    this.queryInputTarget.focus();
    this.queryInputTarget.select();
  }

  #hasBlockingModal() {
    const blockingDialog = document.querySelector("dialog[open]");
    if (!blockingDialog) {
      return false;
    }

    return !this.hasDialogTarget || !this.dialogTarget.contains(blockingDialog);
  }

  #isEditableTarget(target) {
    if (!(target instanceof HTMLElement)) {
      return false;
    }

    if (target.isContentEditable) {
      return true;
    }

    return target.closest(EDITABLE_SELECTOR) !== null;
  }

  #rememberFocusedElement() {
    const activeElement = document.activeElement;

    if (
      activeElement instanceof HTMLElement &&
      activeElement !== document.body
    ) {
      this.previouslyFocusedElement = activeElement;
      return;
    }

    this.previouslyFocusedElement = null;
  }

  #restoreFocus() {
    if (!(this.previouslyFocusedElement instanceof HTMLElement)) {
      return;
    }

    if (!this.previouslyFocusedElement.isConnected) {
      this.previouslyFocusedElement = null;
      return;
    }

    try {
      this.previouslyFocusedElement.focus({ preventScroll: true });
    } catch {
      // Ignore focus restoration failures for detached/disabled elements.
    } finally {
      this.previouslyFocusedElement = null;
    }
  }

  #isMobileViewport() {
    return window.matchMedia(MOBILE_BREAKPOINT_QUERY).matches;
  }

  #syncTriggerState(expanded) {
    const value = String(expanded);

    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute("aria-expanded", value);
    }

    if (this.hasMobileTriggerTarget) {
      this.mobileTriggerTarget.setAttribute("aria-expanded", value);
    }
  }
}
