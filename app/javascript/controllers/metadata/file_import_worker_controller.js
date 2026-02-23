import * as XLSX from "xlsx";

import { Controller } from "@hotwired/stimulus";
import { notifyRefreshControllers } from "utilities/refresh";

export default class extends Controller {
  static outlets = [
    "viral--dialog",
    "viral--flash",
    "viral--progress-bar",
    "viral--sortable-lists--two-lists-selection",
    "refresh",
  ];

  static targets = [
    "sampleIdColumn",
    "metadataColumns",
    "submitButton",
    "error",
  ];

  static values = {
    groupId: String,
  };

  #defaultSampleColumnHeaders = [
    "sample",
    "sample_id",
    "sample id",
    "sample_puid",
    "sample puid",
    "sample_name",
    "sample name",
  ];

  #ignoreList = [
    "sample_name",
    "sample name",
    "sample",
    "sample_id",
    "sample id",
    "sample_puid",
    "sample puid",
    "project id",
    "project_id",
    "project_puid",
    "project puid",
    "created_at",
    "updated_at",
    "last_updated_at",
    "description",
  ];

  #columns = [];
  #hasErrors = false;
  #headers = [];
  #worksheet = null;
  #worker = null;

  connect() {
    console.log("connecting worker");
    if (typeof Worker !== "undefined") {
      this.#worker = new Worker(
        import.meta.resolve("workers/file_import_worker"),
        { type: "module" },
      );

      this.#worker.onerror = (error) => {
        console.error("Worker failed to load:", error.message);
      };

      // Listen for messages from the worker
      this.#worker.onmessage = (e) => {
        console.log("Main thread received:", e.data);
        if (!e.success) {
          this.#hasErrors = true;
          this.#addErrorMessage(e.data.error);
        }
      };
    } else {
      console.error("Web Workers are not supported in this browser.");
    }
  }

  disconnect() {
    this.#worker.terminate(); //TODO: Give the user the ability to navigate to other pages
  }

  changeSampleIDInput(event) {
    const { value } = event.target;
    if (value) {
      this.#enableDialogState();
      this.#sortableListsConnect();
    } else {
      this.#resetDialogState();
    }
  }

  readFile(event) {
    const { files } = event.target;

    this.#removeSampleIDInputOptions();
    this.#resetDialogState();
    this.#disableErrorState();
    if (!files.length) {
      return;
    }

    const reader = new FileReader();
    reader.readAsArrayBuffer(files[0]);

    reader.onload = () => {
      const workbook = XLSX.read(reader.result);
      const worksheetName = workbook.SheetNames[0];
      this.#worksheet = workbook.Sheets[worksheetName];
      this.#headers = XLSX.utils.sheet_to_json(this.#worksheet, {
        header: 1,
      })[0];
      //   this.#rows = XLSX.utils.sheet_to_json(this.#worksheet);
      this.#addSampleIDInputOptions();
    };
  }

  handleSubmit() {
    this.#processRows();
    notifyRefreshControllers(this);
  }

  show() {
    if (this.hasViralProgressBarOutlet) {
      this.viralProgressBarOutlet.show();
    }
  }

  complete() {
    if (this.hasViralProgressBarOutlet) {
      this.viralProgressBarOutlet.hide();
    }

    if (this.#hasErrors) {
      if (this.hasViralDialogOutlet) {
        this.viralDialogOutlet.open();
      }
    } else {
      if (this.hasViralFlashOutlet) {
        this.viralFlashOutletElement.classList.remove("hidden");
      }
    }
  }

  #removeSampleIDInputOptions() {
    this.#removeInputOptions(this.sampleIdColumnTarget);
    this.#disableTarget(this.sampleIdColumnTarget);
  }

  #addSampleIDInputOptions() {
    for (const header of this.#headers) {
      const option = document.createElement("option");
      option.value = header;
      option.text = header;
      this.sampleIdColumnTarget.append(option);
    }
    // lower case to test for case insensitivity
    const allHeadersToLowerCase = this.#headers.map((header) =>
      header.toLowerCase(),
    );
    for (const sampleColumnHeader of this.#defaultSampleColumnHeaders) {
      const sampleIndex = allHeadersToLowerCase.indexOf(sampleColumnHeader);
      if (sampleIndex > -1) {
        this.sampleIdColumnTarget.value = this.#headers[sampleIndex];
        this.#enableDialogState();
        this.#sortableListsConnect();
        break;
      }
    }
    this.#enableTarget(this.sampleIdColumnTarget);
  }

  #addMetadataColumns() {
    this.#columns = this.#headers.filter(
      (header) =>
        !this.#ignoreList.includes(header.toLowerCase()) &&
        header.toLowerCase() != this.sampleIdColumnTarget.value.toLowerCase(),
    );

    if (this.#columns.length > 0) {
      this.#unhideElement(this.metadataColumnsTarget);

      this.dispatch("sendMetadata", {
        detail: { content: { metadata: this.#columns } },
      });

      this.submitButtonTarget.disabled = !this.#columns.length;
    } else {
      this.#hideElement(this.metadataColumnsTarget);
      this.#enableErrorState();
    }
  }

  #removeInputOptions(target) {
    while (target.options.length > 1) {
      target.remove(target.options.length - 1);
    }
  }

  #disableTarget(target) {
    target.disabled = true;
    target.setAttribute("aria-disabled", "true");
  }

  #enableTarget(target) {
    target.disabled = false;
    target.removeAttribute("aria-disabled");
  }

  #resetDialogState() {
    this.#disableTarget(this.submitButtonTarget);
    if (this.hasMetadataColumnsTarget) {
      this.#hideElement(this.metadataColumnsTarget);
      this.errorTarget.setAttribute("aria-disabled", "true");
    }
  }

  #enableDialogState() {
    this.#enableTarget(this.submitButtonTarget);
    if (this.hasMetadataColumnsTarget) {
      this.#addMetadataColumns();
    }
  }

  #disableErrorState() {
    this.#hideElement(this.errorTarget);
  }

  #enableErrorState() {
    this.#unhideElement(this.errorTarget);
    this.#disableTarget(this.submitButtonTarget);
  }

  #hideElement(element) {
    element.classList.add("hidden");
    element.setAttribute("aria-hidden", "true");
  }

  #unhideElement(element) {
    element.classList.remove("hidden");
    element.removeAttribute("aria-hidden");
  }

  #sortableListsConnect() {
    if (this.hasViralSortableListsTwoListsSelectionOutlet) {
      this.viralSortableListsTwoListsSelectionOutlet.idempotentConnect();
    }
  }

  #processRows() {
    // filter rows to only include sample id and selected metadata columns
    const rows = XLSX.utils.sheet_to_json(this.#worksheet, {
      header: [this.sampleIdColumnTarget.value, ...this.#columns],
      range: 1,
    });

    let count = 0;
    const total = rows.length;

    rows.forEach((row) => {
      const id = Object.values(row)[0];
      const metadata = Object.entries(row).slice(1);

      console.log("count = ", count);
      console.log("row = ", row);
      console.log("id = ", id);
      console.log("metadata = ", metadata);

      // Send data to worker
      this.#worker.postMessage({
        groupId: this.groupIdValue,
        sampleNameOrPuid: id,
        metadata: Object.fromEntries(metadata),
      });

      if (this.hasViralProgressBarOutlet) {
        this.viralProgressBarOutlet.updatePercentageValue(
          (++count / total) * 100,
        );
      }
    });
  }

  #addErrorMessage(error) {
    if (this.hasViralDialogOutlet) {
      const template = this.viralDialogOutletElement.querySelector(
        "#file-import-dialog-template",
      );
      const errorMessage = template.innerHTML.replace(/PLACEHOLDER/g, error);
      template.insertAdjacentHTML("afterend", errorMessage);
    }
  }
}
