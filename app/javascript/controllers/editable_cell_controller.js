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
    this.#originalCellContent = {};
  }

  editableCellTargetConnected(element) {
    const elementId = this.#elementId(element);

    // Skip initialization if we can't determine element ID
    if (!elementId) {
      console.warn(
        "Skipping editable cell initialization - no field ID found",
        element,
      );
      return;
    }

    element.id = elementId;

    this.#originalCellContent[element.id] = element.innerText;
    element.addEventListener("blur", this.boundBlur);
    element.addEventListener("keydown", this.boundKeydown);
    element.addEventListener("focus", this.boundFocus);
    element.setAttribute("contenteditable", true);

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
      element.removeAttribute("contenteditable");
      const field = element
        .closest("table")
        .querySelector(`th:nth-child(${element.cellIndex + 1})`)
        .dataset.fieldId;

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
    if (event.key === "Enter") {
      event.preventDefault();
    }

    if (event.key !== "Enter" || this.#unchanged(event.target)) return;

    this.submit(event.target);
  }

  async showConfirmDialog(editableCell) {
    const elementId = this.#elementId(editableCell);
    if (!elementId) return;

    const originalValue = this.#originalCellContent[elementId] || "";

    const validEntry = this.#validateEntry(editableCell);
    if (validEntry) {
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

          e.target.value === "confirm"
            ? this.submit(editableCell)
            : this.reset(editableCell);
          dialog.close();
        },
        { once: true },
      );

      // Handle dialog close
      dialog.addEventListener(
        "close",
        () => {
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
    event.target.dataset.editing = "true";
  }

  #clearEditingState(element) {
    if (!element) return;
    delete element.dataset.editing;
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
      console.warn("Could not determine field ID for cell", element);
      return null;
    }

    const sanitizedField = field.replaceAll(" ", "SPACE");
    return `${sanitizedField}_${element.parentNode.rowIndex}`;
  }
}
