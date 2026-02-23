import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";
import { announce } from "utilities/live_region";

const EDITABLE_SELECTOR =
  "input, textarea, select, [contenteditable]:not([contenteditable='false'])";

/**
 * Global search command-palette controller.
 *
 * Contract:
 * - Targets: `dialog`, `form`, `queryInput`
 * - Values: `path`, `openedAnnouncement`, `closedAnnouncement`
 * - Actions:
 *   - `keydown@window->global-search-dialog#handle`
 *   - `cancel->global-search-dialog#handleCancel:prevent`
 *   - `click->global-search-dialog#handleBackdropClick:self`
 *   - `submit->global-search-dialog#handleSubmit`
 */
export default class extends Controller {
  static targets = [
    "dialog",
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
  }

  disconnect() {
    this.previouslyFocusedElement = null;
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
    this.openDialog();
  }

  openDialog() {
    if (!this.hasDialogTarget) {
      this.#visitSearchPage();
      return;
    }

    if (!this.dialogTarget.open) {
      this.#rememberFocusedElement();

      if (!this.#showDialog()) {
        this.#visitSearchPage();
        return;
      }

      this.#announceOpened();
    }

    this.#focusSearchInput();
  }

  close() {
    this.#closeAndClear();
  }

  handleCancel() {
    this.#closeAndClear();
  }

  handleBackdropClick() {
    this.#closeAndClear();
  }

  handleSubmit() {
    if (this.hasDialogTarget && this.dialogTarget.open) {
      this.dialogTarget.close();
    }
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

    if (this.hasDialogTarget && this.dialogTarget.open) {
      this.dialogTarget.close();
      this.#announceClosed();
      this.#restoreFocus();
    }
  }

  #showDialog() {
    try {
      this.dialogTarget.showModal();
      return true;
    } catch (error) {
      console.error("Failed to open global search dialog.", error);
      return false;
    }
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

    return !this.hasDialogTarget || blockingDialog !== this.dialogTarget;
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
}
