import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "formContainer",
    "formTemplate",
    "editableCell",
    "confirmDialogContainer",
    "confirmDialogTemplate",
  ];
  #originalCellContent;

  initialize() {
    this.boundBlur = this.blur.bind(this);
    this.boundKeydown = this.keydown.bind(this);
    this.#originalCellContent = {};
  }

  editableCellTargetConnected(element) {
    this.#originalCellContent[this.#elementId(element)] = element.innerText;
    element.addEventListener("blur", this.boundBlur);
    element.addEventListener("keydown", this.boundKeydown);
  }

  editableCellTargetDisconnected(element) {
    element.removeEventListener("blur", this.boundBlur);
    element.removeEventListener("keydown", this.boundKeydown);
  }

  submit(element) {
    let field = element
      .closest("table")
      .querySelector(`th:nth-child(${element.cellIndex + 1})`).dataset.fieldId;
    let sampleId = element.parentNode.id;
    let cellId = this.#elementId(element);
    element.id = cellId;
    let form = this.formTemplateTarget.innerHTML
      .replace(/SAMPLE_ID_PLACEHOLDER/g, sampleId)
      .replace(/FIELD_ID_PLACEHOLDER/g, encodeURIComponent(field))
      .replace(/FIELD_VALUE_PLACEHOLDER/g, element.innerText)
      .replace(/CELL_ID_PLACEHOLDER/g, cellId);
    this.formContainerTarget.innerHTML = form;
    this.formContainerTarget.getElementsByTagName("form")[0].requestSubmit();
  }

  reset(element) {
    element.innerText = this.#originalCellContent[element.id];
  }

  async blur(event) {
    if (event.type === "input" || this.#unchanged(event.target)) return;

    event.preventDefault();

    await this.showConfirmDialog(event.target);
  }

  keydown(event) {
    if (event.key !== "Enter" || this.#unchanged(event.target)) return;

    event.preventDefault();
    this.submit(event.target);
  }

  async showConfirmDialog(editableCell) {
    let confirmDialog = this.confirmDialogTemplateTarget.innerHTML
      .replace(/ORIGINAL_VALUE/g, this.#originalCellContent[editableCell.id])
      .replace(/NEW_VALUE/g, editableCell.innerText);
    this.confirmDialogContainerTarget.innerHTML = confirmDialog;

    let dialog =
      this.confirmDialogContainerTarget.getElementsByTagName("dialog")[0];

    let messageType = "wov";
    if (editableCell.innerText === "") {
      messageType = "wonv";
    } else if (editableCell.dataset.originalValue === "") {
      messageType = "woov";
    }
    dialog
      .querySelector(`[data-message-type="${messageType}"]`)
      .classList.remove("hidden");

    dialog.showModal();

    // Focus the cancel button for accessibility
    const cancelButton = dialog.querySelector('button[value="cancel"]');
    if (cancelButton) {
      requestAnimationFrame(() => cancelButton.focus());
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

  #unchanged(element) {
    return (
      element.innerText === this.#originalCellContent[this.#elementId(element)]
    );
  }

  #elementId(element) {
    return `${element.cellIndex}_${element.parentNode.rowIndex}`;
  }
}
