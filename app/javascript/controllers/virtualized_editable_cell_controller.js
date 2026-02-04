import { Controller } from "@hotwired/stimulus";
import { notifyRefreshControllers } from "utilities/refresh";
import { focusWhenVisible } from "utilities/focus";

/**
 * VirtualizedEditableCellController
 *
 * Manages editable cells within virtualized tables where cells are dynamically
 * created and destroyed during scrolling. Handles the unique challenges of:
 * - Cells being reattached/detached during horizontal scroll
 * - ARIA attributes being stripped by Turbo Stream replacement
 * - Focus preservation across virtualization cycles
 * - Navigation-aware blur handling to prevent conflicts with keyboard navigation
 *
 * Key differences from editable_cell_controller:
 * - Uses crypto.randomUUID() for stable cell identification across reattach cycles
 * - Extracts field ID from data-field-id attribute (not header lookup)
 * - Extracts item ID from data-sample-id on parent row (not DOM ID parsing)
 * - Restores ARIA attributes after Turbo Stream replacement
 * - Dispatches edit-mode events for screen reader announcements
 * - Manages contenteditable state for explicit edit mode activation
 */
export default class extends Controller {
  static targets = [
    "formContainer",
    "formTemplate",
    "editableCell",
    "confirmDialogContainer",
    "confirmDialogTemplate",
  ];

  // Outlet to refresh controller - used to prevent false-positive refresh notices
  // when user edits cells (since edits trigger broadcasts).
  static outlets = ["refresh"];

  // Stimulus values for i18n screen reader announcements
  static values = {
    editActivatedMessage: String,
    editDeactivatedMessage: String,
  };

  #originalCellContent;

  initialize() {
    this.boundBlur = this.blur.bind(this);
    this.boundKeydown = this.keydown.bind(this);
    this.boundClick = this.click.bind(this);
    this.boundHandleEditActivated = this.#handleEditActivated.bind(this);
    this.boundHandleEditDeactivated = this.#handleEditDeactivated.bind(this);
    this.#originalCellContent = {};
  }

  connect() {
    // Listen for edit mode events for screen reader announcements
    this.element.addEventListener(
      "edit-mode-activated",
      this.boundHandleEditActivated,
    );
    this.element.addEventListener(
      "edit-mode-deactivated",
      this.boundHandleEditDeactivated,
    );
  }

  disconnect() {
    // Clean up controller-level event listeners
    // Note: Target-level listeners (blur, keydown, click) are automatically
    // cleaned up in editableCellTargetDisconnected() when targets are removed
    this.element.removeEventListener(
      "edit-mode-activated",
      this.boundHandleEditActivated,
    );
    this.element.removeEventListener(
      "edit-mode-deactivated",
      this.boundHandleEditDeactivated,
    );
  }

  editableCellTargetConnected(element) {
    const elementId = this.#elementId(element);

    // Skip initialization if we can't determine element ID
    if (!elementId) {
      return;
    }

    element.id = elementId;

    // Only initialize original content if not already tracked.
    // This preserves the original value during reattach cycles (e.g., horizontal scroll
    // in virtualized tables) so that in-progress edits are not lost.
    if (!(elementId in this.#originalCellContent)) {
      this.#originalCellContent[element.id] = element.innerText;
    }

    element.addEventListener("blur", this.boundBlur);
    element.addEventListener("keydown", this.boundKeydown);
    element.addEventListener("click", this.boundClick);
    element.setAttribute("data-editable", "true");
    element.setAttribute("contenteditable", "false");
    // Note: aria-readonly is only set during edit mode (contenteditable="true")
    // W3C spec only allows aria-readonly="false" on contenteditable elements

    // Make sure the cell remains focusable after Turbo Stream replacement.
    // Virtual scroll/grid navigation expects cells to participate in roving tabindex.
    if (!element.hasAttribute("tabindex")) {
      element.setAttribute("tabindex", "-1");
    }

    // Turbo Stream `replace` swaps the entire <td>, which can drop ARIA attributes
    // required by grid navigation/edit activation logic (it relies on `[aria-colindex]`).
    // Restore a reasonable default when missing.
    if (
      !element.hasAttribute("aria-colindex") &&
      Number.isInteger(element.cellIndex)
    ) {
      element.setAttribute("aria-colindex", String(element.cellIndex + 1));
    }

    if (!element.hasAttribute("role")) {
      element.setAttribute("role", "gridcell");
    }

    if (element.hasAttribute("data-refocus")) {
      element.removeAttribute("data-refocus");
      element.focus();
    }
  }

  editableCellTargetDisconnected(element) {
    element.removeEventListener("blur", this.boundBlur);
    element.removeEventListener("keydown", this.boundKeydown);
    element.removeEventListener("click", this.boundClick);
  }

  submit(element) {
    const validEntry = this.#validateEntry(element);
    if (validEntry) {
      this.#deactivateEditMode(element);

      // Clear the stored original content for this cell. After Turbo Stream replaces
      // the cell, the new cell should capture its updated content as the new original.
      const elementId = this.#elementId(element);
      if (elementId) {
        delete this.#originalCellContent[elementId];
      }

      // Remove event listeners on submission, they will be re-added on successful update
      element.removeEventListener("blur", this.boundBlur);
      element.removeEventListener("keydown", this.boundKeydown);
      // Use explicit field-id attribute (virtualized cells always have this)
      const field = element.dataset.fieldId;
      if (!field) return;

      // Get the parent row to extract the item ID via data-sample-id attribute
      const row = element.closest("tr");
      const item_id = row?.dataset?.sampleId;

      if (!item_id) {
        return;
      }

      notifyRefreshControllers(this);

      const ariaColindex =
        element.getAttribute("aria-colindex") ??
        (Number.isInteger(element.cellIndex)
          ? String(element.cellIndex + 1)
          : "");

      const form = this.formTemplateTarget.innerHTML
        .replace(/SAMPLE_ID_PLACEHOLDER/g, item_id)
        .replace(/FIELD_ID_PLACEHOLDER/g, encodeURIComponent(field))
        .replace(
          /FIELD_VALUE_PLACEHOLDER/g,
          this.#trimWhitespaces(element.innerText),
        )
        .replace(/CELL_ID_PLACEHOLDER/g, element.id)
        .replace(/ARIA_COLINDEX_PLACEHOLDER/g, ariaColindex);
      this.formContainerTarget.innerHTML = form;
      this.formContainerTarget.getElementsByTagName("form")[0].requestSubmit();
    }
  }

  reset(element) {
    const elementId = this.#elementId(element);
    if (!elementId) return;
    element.innerText = this.#originalCellContent[elementId];
    this.#deactivateEditMode(element);
    // Maintain focus on the cell after reset
    element.focus();
  }

  async blur(event) {
    if (event.type === "input") return;

    if (this.#unchanged(event.target)) {
      this.#clearEditingState(event.target);
      return;
    }

    event.preventDefault();

    await this.showConfirmDialog(event.target);
  }

  keydown(event) {
    const isEditing = event.target.dataset.editing === "true";

    // Tab: submit if changed, then clear editing state and navigate
    if (event.key === "Tab" && isEditing) {
      if (!this.#unchanged(event.target)) {
        // Submit changes (this will clear editing state)
        this.submit(event.target);
      } else {
        // No changes, just clear editing state
        this.#deactivateEditMode(event.target, { announce: true });
      }
      // Let Tab navigate (don't prevent default)
      return;
    }

    // Escape: exit edit mode and restore original content
    if (event.key === "Escape" && isEditing) {
      event.preventDefault();
      this.#exitEditMode(event.target);
      return;
    }

    // Enter: prevent default always
    if (event.key === "Enter") {
      event.preventDefault();
    }

    // Enter: submit if editing and content changed
    if (event.key !== "Enter" || this.#unchanged(event.target)) return;

    event.stopPropagation();
    this.submit(event.target);
  }

  async showConfirmDialog(editableCell) {
    const elementId = this.#elementId(editableCell);
    if (!elementId) return;

    const originalValue = this.#originalCellContent[elementId] || "";

    const validEntry = this.#validateEntry(editableCell);
    if (validEntry) {
      let didConfirm = false;

      const confirmDialog = this.confirmDialogTemplateTarget.innerHTML
        .replace(/ORIGINAL_VALUE/g, originalValue)
        .replace(/NEW_VALUE/g, this.#trimWhitespaces(editableCell.innerText));
      this.confirmDialogContainerTarget.innerHTML = confirmDialog;

      const dialog =
        this.confirmDialogContainerTarget.getElementsByTagName("dialog")[0];

      let messageType = "wov";
      if (editableCell.innerText === "") {
        messageType = "wonv";
      } else if (originalValue === "") {
        messageType = "woov";
      }
      dialog
        .querySelector(`[data-message-type="${messageType}"]`)
        .classList.remove("hidden");

      dialog.showModal();

      // Focus the cancel button for accessibility
      const cancelButton = dialog.querySelector('button[value="cancel"]');
      if (cancelButton) {
        focusWhenVisible(cancelButton);
      }

      // Handle dialog actions
      dialog.addEventListener(
        "click",
        (e) => {
          if (e.target.tagName !== "BUTTON") return;

          didConfirm = e.target.value === "confirm";

          if (didConfirm) {
            this.submit(editableCell);
          } else {
            this.reset(editableCell);
          }
          dialog.close();
        },
        { once: true },
      );

      // Handle dialog close
      dialog.addEventListener(
        "close",
        () => {
          if (didConfirm) return;
          this.reset(editableCell);
        },
        { once: true },
      );
    }
  }

  #unchanged(element) {
    const elementId = this.#elementId(element);
    if (!elementId) return true; // Treat as unchanged if we can't determine ID
    return element.innerText === this.#originalCellContent[elementId];
  }

  #validateEntry(metadataCell) {
    const strippedMetadataValue = this.#trimWhitespaces(metadataCell.innerText);
    const elementId = this.#elementId(metadataCell);
    if (!elementId) return false;

    const entryIsValid =
      strippedMetadataValue !== this.#originalCellContent[elementId];
    if (!entryIsValid) {
      metadataCell.innerText = this.#originalCellContent[elementId];
    }

    return entryIsValid;
  }

  #trimWhitespaces(string) {
    return string.replace(/\s+/g, " ").trim();
  }

  click(event) {
    // Activate edit mode on click (matches existing behavior of non-virtualized table)
    this.#activateEditMode(event.target);
  }

  #clearEditingState(element) {
    if (!element) return;
    delete element.dataset.editing;
  }

  /**
   * Activates edit mode on a cell by setting contenteditable and editing state.
   * Does nothing if the cell is already in edit mode.
   *
   * @param {HTMLElement} element - The editable cell element
   */
  #activateEditMode(element) {
    if (!element || element.dataset.editing === "true") return;

    element.dataset.editing = "true";
    element.setAttribute("contenteditable", "true");
    element.setAttribute("aria-readonly", "false");

    // Select all text for visual feedback and immediate typing replacement
    const selection = window.getSelection();
    const range = document.createRange();
    range.selectNodeContents(element);
    selection.removeAllRanges();
    selection.addRange(range);

    // Dispatch event for screen reader announcement
    element.dispatchEvent(
      new CustomEvent("edit-mode-activated", { bubbles: true }),
    );
  }

  #exitEditMode(element) {
    this.reset(element); // Restore original content, exit edit mode, and maintain focus
    this.#deactivateEditMode(element, { announce: true });
  }

  /**
   * Deactivates edit mode on a cell by clearing editing state and disabling contenteditable.
   *
   * @param {HTMLElement} element - The editable cell element
   * @param {Object} options - Configuration options
   * @param {boolean} [options.announce=false] - Whether to dispatch an event for screen reader announcement
   */
  #deactivateEditMode(element, { announce = false } = {}) {
    if (!element) return;
    this.#clearEditingState(element);
    element.setAttribute("contenteditable", "false");
    element.removeAttribute("aria-readonly");

    if (announce) {
      element.dispatchEvent(
        new CustomEvent("edit-mode-deactivated", { bubbles: true }),
      );
    }
  }

  #handleEditActivated() {
    if (this.hasEditActivatedMessageValue) {
      this.#announce(this.editActivatedMessageValue);
    }
  }

  #handleEditDeactivated() {
    if (this.hasEditDeactivatedMessageValue) {
      this.#announce(this.editDeactivatedMessageValue);
    }
  }

  #announce(message) {
    // Find the live region via controller
    const liveRegion = this.element.querySelector(
      '[data-controller="announcement"]',
    );
    if (liveRegion) {
      const controller = this.application.getControllerForElementAndIdentifier(
        liveRegion,
        "announcement",
      );
      controller?.announce(message);
    }
  }

  /**
   * Generate a stable element ID for tracking original cell content.
   * Uses the field ID and a crypto.randomUUID() based approach that persists
   * across reattach cycles within the same controller instance.
   *
   * @param {HTMLElement} element - The editable cell element
   * @returns {string|null} - A unique identifier for the cell, or null if unavailable
   */
  #elementId(element) {
    // If element already has an ID assigned by us, return it
    if (element.id && element.id in this.#originalCellContent) {
      return element.id;
    }

    // Get field ID from data attribute (required for virtualized cells)
    const field = element.dataset.fieldId;
    if (!field) {
      return null;
    }

    // Get row to extract sample ID for a unique cell identifier
    const row = element.closest("tr");
    const sampleId = row?.dataset?.sampleId;
    if (!sampleId) {
      return null;
    }

    // Create a deterministic ID based on sample and field for tracking across reattach cycles
    const sanitizedField = field.replaceAll(" ", "SPACE");
    const cellKey = `${sampleId}_${sanitizedField}`;

    // Look for existing entry in originalCellContent that matches this key pattern
    for (const existingId of Object.keys(this.#originalCellContent)) {
      if (existingId.endsWith(`_${cellKey}`)) {
        return existingId;
      }
    }

    // Generate a new unique ID using crypto.randomUUID()
    return `${crypto.randomUUID()}_${cellKey}`;
  }
}
