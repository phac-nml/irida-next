import { Controller } from "@hotwired/stimulus";
import { notifyRefreshControllers } from "utilities/refresh";
import { focusWhenVisible } from "utilities/focus";

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
  #originalCellContent;

  initialize() {
    this.boundBlur = this.blur.bind(this);
    this.boundKeydown = this.keydown.bind(this);
    this.boundFocus = this.focus.bind(this);
    this.boundHandleEditActivated = this.#handleEditActivated.bind(this);
    this.boundHandleEditDeactivated = this.#handleEditDeactivated.bind(this);
    this.#originalCellContent = {};
  }

  connect() {
    // Listen for edit mode events
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
    // Note: Target-level listeners (blur, keydown, focus) are automatically
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

    this.#originalCellContent[element.id] = element.innerText;
    element.addEventListener("blur", this.boundBlur);
    element.addEventListener("keydown", this.boundKeydown);
    element.addEventListener("focus", this.boundFocus);
    element.setAttribute("data-editable", "true");
    element.setAttribute("contenteditable", "false");

    if (element.hasAttribute("data-refocus")) {
      element.focus();
    }
  }

  editableCellTargetDisconnected(element) {
    element.removeEventListener("blur", this.boundBlur);
    element.removeEventListener("keydown", this.boundKeydown);
    element.removeEventListener("focus", this.boundFocus);
  }

  submit(element) {
    const validEntry = this.#validateEntry(element);
    if (validEntry) {
      this.#clearEditingState(element);
      // Remove event listeners on submission, they will be re-added on succesfull update
      element.removeEventListener("blur", this.boundBlur);
      element.removeEventListener("keydown", this.boundKeydown);
      element.setAttribute("contenteditable", "false");

      // Prefer explicit field-id (works with virtualization/spacers)
      let field = element.dataset.fieldId;

      // Fall back to header lookup by cellIndex (non-virtualized / legacy)
      if (!field) {
        const header = element
          .closest("table")
          .querySelector(`th:nth-child(${element.cellIndex + 1})`);
        field = header?.dataset?.fieldId;
      }

      if (!field) return;

      // Get the parent DOM ID to extract the item ID
      // Use a regular expression to match the part after the last underscore
      const parent_dom_id = element.parentNode.id;
      const item_id = parent_dom_id.match(/_([^_]+)$/)?.[1];

      if (!item_id) {
        console.error("Unable to extract item ID from DOM ID:", parent_dom_id);
        return;
      }

      notifyRefreshControllers(this);

      const form = this.formTemplateTarget.innerHTML
        .replace(/SAMPLE_ID_PLACEHOLDER/g, item_id)
        .replace(/FIELD_ID_PLACEHOLDER/g, encodeURIComponent(field))
        .replace(
          /FIELD_VALUE_PLACEHOLDER/g,
          this.#trimWhitespaces(element.innerText),
        )
        .replace(/CELL_ID_PLACEHOLDER/g, element.id);
      this.formContainerTarget.innerHTML = form;
      this.formContainerTarget.getElementsByTagName("form")[0].requestSubmit();
    }
  }

  reset(element) {
    const elementId = this.#elementId(element);
    if (!elementId) return;
    element.innerText = this.#originalCellContent[elementId];
    this.#clearEditingState(element);
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
        this.#clearEditingState(event.target);
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

      let confirmDialog = this.confirmDialogTemplateTarget.innerHTML
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

  focus(event) {
    // Don't automatically set editing mode on focus
    // Edit mode is only activated by Enter, F2, or alphanumeric keys
  }

  #clearEditingState(element) {
    if (!element) return;
    delete element.dataset.editing;
  }

  #exitEditMode(element) {
    this.reset(element); // Restore original content
    this.#clearEditingState(element);
    element.setAttribute("contenteditable", "false");
    element.blur(); // Return to navigation mode

    // Dispatch custom event for screen reader announcement
    element.dispatchEvent(
      new CustomEvent("edit-mode-deactivated", { bubbles: true }),
    );
  }

  #handleEditActivated() {
    this.#announce("Edit mode activated");
  }

  #handleEditDeactivated() {
    this.#announce("Edit mode deactivated, navigating");
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

  #elementId(element) {
    // First try to get field ID directly from cell (for virtualized cells)
    let field = element.dataset.fieldId;

    // Fall back to finding header by cellIndex (for non-virtualized cells)
    if (!field) {
      const header = element
        .closest("table")
        .querySelector(`th:nth-child(${element.cellIndex + 1})`);
      field = header?.dataset.fieldId;
    }

    // Handle undefined field gracefully
    if (!field) {
      return null;
    }

    const sanitizedField = field.replaceAll(" ", "SPACE");
    return `${sanitizedField}_${element.parentNode.rowIndex}`;
  }
}
