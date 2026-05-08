import * as XLSX from "xlsx";
import Controller from "controllers/metadata/file_import_controller";
import { chunk, pick } from "utilities/collection";

const ROW_CHUNK_SIZE = 2;
export default class extends Controller {
  static values = {
    graphqlUrl: String,
    groupPuid: String,
    projectPuid: String,
  };

  connect() {
    super.connect();
    this._chunksReceived = 0;
    this._hasErrors = false;
    this._totalChunks = 0;
    this._worker ||= this.#buildWorker();
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

    const reader = new FileReader();
    reader.readAsArrayBuffer(files[0]);

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

  handleSubmit() {
    this.#processRows();
    super.handleSubmit();
  }

  #processRows() {
    const allRows = XLSX.utils.sheet_to_json(this._worksheet, {
      header: this.headers,
      range: 1,
    });

    const rows = allRows.map((row) => [
      row[this.sampleIdColumnTarget.value],
      pick(row, this.columns),
    ]);

    const rowChunks = chunk(rows, ROW_CHUNK_SIZE);
    this._totalChunks = rowChunks.length;

    for (const row of rowChunks) {
      // Send data to worker
      this._worker.postMessage({
        graphql_url: this.graphqlUrlValue,
        csrf_token: this.#csrfToken(),
        group_puid: this.groupPuidValue,
        project_puid: this.projectPuidValue,
        metadata: Object.fromEntries(row),
      });
    }
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
        this._chunksReceived++;

        console.log("Main thread received:", event.data);

        if (this._chunksReceived === this._totalChunks) {
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
