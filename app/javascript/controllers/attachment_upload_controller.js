import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["submitButton", "attachmentsInput"];
  static values = {
    uploadingText: String,
  };

  connect() {
    // Keep references to bound handlers so we can remove them on disconnect
    this._onInit = this.uploadInitialize.bind(this);
    this._onStart = this.uploadStart.bind(this);
    this._onProgress = this.uploadProgress.bind(this);
    this._onError = this.uploadError.bind(this);
    this._onEnd = this.uploadEnd.bind(this);

    this.element.addEventListener("direct-upload:initialize", this._onInit);
    this.element.addEventListener("direct-upload:start", this._onStart);
    this.element.addEventListener("direct-upload:progress", this._onProgress);
    this.element.addEventListener("direct-upload:error", this._onError);
    this.element.addEventListener("direct-upload:end", this._onEnd);
    this.attachmentsInputTarget.setAttribute("aria-required", true);
    this.attachmentsInputTarget.setAttribute("aria-invalid", false);
    this.submitButtonTarget.disabled = true;
  }

  uploadInitialize(event) {
    const { target, detail } = event;
    const { id, file } = detail;

    target.insertAdjacentHTML(
      "beforebegin",
      `
      <div id="direct-upload-${id}" class="direct-upload direct-upload--pending flex-1 relative mb-1">
        <div class="flex justify-between mb-1 direct-upload__filename">
          <span class="text-sm text-gray-500 dark:text-gray-400" id="direct-upload-filename-${id}"></span>
          <span class="text-sm text-gray-500 dark:text-gray-400" id="upload-progress-${id}">0%</span>
        </div>
        <div class="w-full bg-gray-200 rounded-full h-2.5 dark:bg-gray-700">
          <div
            class="bg-primary-600 h-2.5 rounded-full"
            style="width: 0"
            id="direct-upload-progress-${id}"
            role="progressbar"
            aria-valuemin="0"
            aria-valuemax="100"
            aria-valuenow="0"
            aria-valuetext="0%"
            aria-label="${this.uploadingTextValue}"
          ></div>
        </div>
      </div>
      `,
    );

    // Set text safely to avoid injecting markup
    const nameEl = target.previousElementSibling?.querySelector(
      `#direct-upload-filename-${id}`,
    );
    if (nameEl) nameEl.textContent = file.name;

    // Improve accessible label with file name
    const progressEl = document.getElementById(`direct-upload-progress-${id}`);
    if (progressEl) {
      const ariaLabel = this.uploadingTextValue + " " + file.name;
      progressEl.setAttribute("aria-label", ariaLabel);
      progressEl.setAttribute(
        "aria-describedby",
        `direct-upload-filename-${id}`,
      );
    }

    // Hide input from both sighted users and AT while uploading
    this.attachmentsInputTarget.classList.add("hidden");
    this.attachmentsInputTarget.setAttribute("aria-hidden", "true");

    // Disable submit and set uploading label (support input/button)
    this.submitButtonTarget.disabled = true;
    this.submitButtonTarget.value = this.uploadingTextValue;
  }

  uploadStart(event) {
    const { id } = event.detail;
    const element = document.getElementById(`direct-upload-${id}`);
    element.classList.remove("direct-upload--pending");
  }

  uploadProgress(event) {
    const { id, progress } = event.detail;
    const progressElement = document.getElementById(
      `direct-upload-progress-${id}`,
    );
    progressElement.style.width = `${progress}%`;
    document.getElementById(`upload-progress-${id}`).innerText = `${Math.round(
      progress,
    )}%`;
  }

  uploadError(event) {
    event.preventDefault();
    const { id, error } = event.detail;
    const element = document.getElementById(`direct-upload-${id}`);
    element.classList.add("direct-upload--error", "border-rose-600");
    element.setAttribute("title", error);
  }

  uploadEnd(event) {
    const { id } = event.detail;
    const element = document.getElementById(`direct-upload-${id}`);
    element.classList.add("direct-upload--complete");
  }
  disconnect() {
    this.element.removeEventListener("direct-upload:initialize", this._onInit);
    this.element.removeEventListener("direct-upload:start", this._onStart);
    this.element.removeEventListener(
      "direct-upload:progress",
      this._onProgress,
    );
    this.element.removeEventListener("direct-upload:error", this._onError);
    this.element.removeEventListener("direct-upload:end", this._onEnd);
  }
}
