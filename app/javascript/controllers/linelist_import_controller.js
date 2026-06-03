import * as XLSX from "xlsx";
import Controller from "controllers/metadata/file_import_controller";
import { omitBy, pick } from "utilities/collection";

export default class extends Controller {
  static values = {
    graphqlUrl: String,
    groupPuid: String,
    projectPuid: String,
  };

  connect() {
    super.connect();
    this._filetype = null;
    this._worksheet = null;
  }

  readFile(event) {
    const { files } = event.target;

    super.removeSampleIDInputOptions();
    super.resetDialogState();
    super.disableErrorState();

    if (!files.length) {
      return;
    }

    const file = files[0];
    this._fileType = file.type;
    const reader = new FileReader();
    reader.readAsArrayBuffer(file);

    reader.onload = () => {
      const workbook = XLSX.read(reader.result);
      const worksheetName = workbook.SheetNames[0];
      this._worksheet = workbook.Sheets[worksheetName];
      this.headers = XLSX.utils.sheet_to_json(this._worksheet, {
        header: 1,
      })[0];
      super.addSampleIDInputOptions();
    };
  }

  handleSubmit(event) {
    event.preventDefault();
    event.stopPropagation();
    this._worker?.terminate();
    this._worker ||= this.#buildWorker();
    this.#processRows();
  }

  #processRows() {
    const allRows = XLSX.utils.sheet_to_json(this._worksheet, {
      header: this.headers,
      range: 1,
      defval: null,
    });

    const selectedMetadataColumns = Array.from(
      this.element.querySelectorAll('[name="file_import[metadata_columns][]"]'),
      (el) => el.value,
    );

    const ignoreEmptyValues = this.element.querySelector(
      '[name="file_import[ignore_empty_values]"]',
    ).checked;

    const rows = allRows.map((row) => [
      row[this.sampleIdColumnTarget.value],
      omitBy(
        pick(row, selectedMetadataColumns),
        (value) => ignoreEmptyValues && !value,
      ),
    ]);

    // Send data to worker
    this._worker.postMessage({
      csrf_token: this.#csrfToken(),
      mime_type: this._fileType,
      graphql_url: this.graphqlUrlValue,
      group_puid: this.groupPuidValue,
      project_puid: this.projectPuidValue,
      rows: rows,
    });
  }

  #buildWorker() {
    let worker;

    if (typeof Worker !== "undefined") {
      worker = new Worker(
        import.meta.resolve("workers/linelist_import_worker"),
        { type: "module" },
      );

      worker.onerror = (error) => {
        console.error("Worker failed:", error.message);
        this.#terminateWorker();
      };

      // Listen for messages from the worker
      worker.onmessage = (event) => {
        const payload = event.data || {};

        if (payload.type === "progress") {
          console.log("Progress: ", payload);
        }

        if (payload.type === "done") {
          console.log("Complete");
          this.#terminateWorker();
        }

        if (payload.type === "error") {
          console.log("Error: ", payload);
          this.#terminateWorker();
        }
      };
    } else {
      console.error("Web Workers are not supported in this browser.");
    }

    return worker;
  }

  #csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.getAttribute("content") : "";
  }

  #terminateWorker() {
    if (this._worker) {
      this._worker.terminate();
      this._worker = null;
    }
  }
}
