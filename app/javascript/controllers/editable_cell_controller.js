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
    this.#originalCellContent = {};
  }

  editableCellTargetConnected(element) {
    element.id = this.#elementId(element);

    this.#originalCellContent[element.id] = element.innerText;
    element.addEventListener("blur", this.boundBlur);
    element.addEventListener("keydown", this.boundKeydown);
    element.setAttribute("contenteditable", true);

    if (element.hasAttribute("data-refocus")) {
      element.focus();
    }
  }

  editableCellTargetDisconnected(element) {
    element.removeEventListener("blur", this.boundBlur);
    element.removeEventListener("keydown", this.boundKeydown);
  }

  submit(element) {
    const validEntry = this.#validateEntry(element);
    if (validEntry) {
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
        .replace(/FIELD_VALUE_PLACEHOLDER/g, element.innerText)
        .replace(/CELL_ID_PLACEHOLDER/g, element.id);
      this.formContainerTarget.innerHTML = form;
      this.formContainerTarget.getElementsByTagName("form")[0].requestSubmit();
    }
  }

  reset(element) {
    element.innerText = this.#originalCellContent[this.#elementId(element)];
  }

  async blur(event) {
    if (event.type === "input" || this.#unchanged(event.target)) return;

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
    const validEntry = this.#validateEntry(editableCell);
    if (validEntry) {
      const confirmDialog = this.confirmDialogTemplateTarget.innerHTML
        .replace(
          /ORIGINAL_VALUE/g,
          this.#originalCellContent[this.#elementId(editableCell)],
        )
        .replace(/NEW_VALUE/g, editableCell.innerText);
      this.confirmDialogContainerTarget.innerHTML = confirmDialog;

      const dialog =
        this.confirmDialogContainerTarget.getElementsByTagName("dialog")[0];

      let messageType = "wov";
      if (editableCell.innerText === "") {
        messageType = "wonv";
      } else if (
        this.#originalCellContent[this.#elementId(editableCell)] === ""
      ) {
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
    return (
      element.innerText === this.#originalCellContent[this.#elementId(element)]
    );
  }

  #elementId(element) {
    const field = element
      .closest("table")
      .querySelector(`th:nth-child(${element.cellIndex + 1})`)
      .dataset.fieldId.replaceAll(" ", "SPACE");
    return `${field}_${element.parentNode.rowIndex}`;
  }

  #validateEntry(metadataCell) {
    const strippedMetadataValue = metadataCell.innerText
      .replace(/\s+/g, " ")
      .trim();

    const entryIsValid =
      strippedMetadataValue !==
      this.#originalCellContent[this.#elementId(metadataCell)];
    if (!entryIsValid) {
      metadataCell.innerText =
        this.#originalCellContent[this.#elementId(metadataCell)];
    }

    return entryIsValid;
  }
}
