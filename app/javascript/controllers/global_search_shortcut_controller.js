import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";
import { announce } from "utilities/live_region";

export default class extends Controller {
  static targets = ["dialog", "form", "queryInput"];
  static values = {
    path: String,
    openedAnnouncement: String,
    closedAnnouncement: String,
  };

  handle(event) {
    if (event.defaultPrevented || this.#isEditableTarget(event.target)) {
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
      Turbo.visit(this.pathValue);
      return;
    }

    if (!this.dialogTarget.open) {
      this.dialogTarget.showModal();
      this.#announceOpened();
    }

    this.#focusSearchInput();
  }

  close(event) {
    event.preventDefault();
    this.#closeAndClear();
  }

  handleCancel(event) {
    event.preventDefault();
    this.#closeAndClear();
  }

  handleBackdropClick(event) {
    if (event.target !== this.dialogTarget) {
      return;
    }

    this.#closeAndClear();
  }

  handleSubmit() {
    if (this.dialogTarget.open) {
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
      !event.shiftKey &&
      event.key === "/"
    );
  }

  #closeAndClear() {
    this.#resetForm();

    if (this.dialogTarget.open) {
      this.dialogTarget.close();
      this.#announceClosed();
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

    return (
      target.closest("input, textarea, select, [contenteditable='true']") !==
      null
    );
  }
}
