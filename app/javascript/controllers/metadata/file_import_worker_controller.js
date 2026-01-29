import * as XLSX from "xlsx";

import { Controller } from "@hotwired/stimulus";
import { notifyRefreshControllers } from "utilities/refresh";

export default class extends Controller {
  static outlets = ["viral--sortable-lists--two-lists-selection", "refresh"];
  static targets = [
    "sampleIdColumn",
    "metadataColumns",
    "submitButton",
    "error",
  ];

  #defaultSampleColumnHeaders = [
    "sample_name",
    "sample name",
    "sample",
    "sample_id",
    "sample id",
    "sample_puid",
    "sample puid",
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

  #headers = [];

  connect() {
    console.log("connecting worker");
    if (typeof Worker !== "undefined") {
      this.worker = new Worker(
        import.meta.resolve("workers/file_import_worker"),
      );

      this.worker.onerror = function (error) {
        console.error("Worker failed to load:", error.message);
      };

      // Listen for messages from the worker
      this.worker.onmessage = function (e) {
        console.log("Main thread received:", e.data);
      };
    } else {
      console.error("Web Workers are not supported in this browser.");
    }
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
      const workbook = XLSX.read(reader.result, { sheetRows: 1 });
      const worksheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[worksheetName];
      this.#headers = XLSX.utils.sheet_to_json(worksheet, { header: 1 })[0];
      this.#addSampleIDInputOptions();
    };
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
    const columns = this.#headers.filter(
      (header) =>
        !this.#ignoreList.includes(header.toLowerCase()) &&
        header.toLowerCase() != this.sampleIdColumnTarget.value.toLowerCase(),
    );

    if (columns.length > 0) {
      this.#unhideElement(this.metadataColumnsTarget);

      this.dispatch("sendMetadata", {
        detail: { content: { metadata: columns } },
      });

      this.submitButtonTarget.disabled = !columns.length;
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

  process(num) {
    console.log("process worker = ", num);
    // Send data to worker
    this.worker.postMessage(num);
  }

  handleSubmit() {
    console.log("handling submit via worker");
    this.process(5);
    notifyRefreshControllers(this);
  }

  disconnect() {
    console.log("disconnecting worker");
    // Clean up worker here?
    this.worker.terminate();
  }
}
