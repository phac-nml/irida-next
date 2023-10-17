import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["submitButton"];

    connect() {
        this.element.addEventListener("direct-upload:initialize", event => this.uploadInitialize(event))
        this.element.addEventListener("direct-upload:start", event => this.uploadStart(event))
        this.element.addEventListener("direct-upload:progress", event => this.uploadProgress(event))
        this.element.addEventListener("direct-upload:error", event => this.uploadError(event))
        this.element.addEventListener("direct-upload:end", event => this.uploadEnd(event))
    }

    uploadInitialize(event) {
        const { target, detail } = event
        const { id, file } = detail
        target.insertAdjacentHTML("beforebegin", `
            <div id="direct-upload-${id}"
            class="direct-upload direct-upload--pending flex-1 relative mb-1">
                <div class="flex justify-between mb-1 direct-upload__filename">
                </div>
                <div class="w-full bg-gray-200 rounded-full h-2.5 dark:bg-gray-700">
                    <div class="bg-primary-600 h-2.5 rounded-full" style="width: 0%" id="direct-upload-progress-${id}"></div>
                </div>
            </div>
            `)
        const textColor = localStorage.getItem('theme') == 'dark' ? 'text-blue-700' : 'text-slate-900'
        target.previousElementSibling.querySelector(`.direct-upload__filename`).innerHTML =
            `<span class="text-base font-medium ${textColor} dark:text-white">${file.name}</span>
            <span class="text-sm font-medium ${textColor} dark:text-white" id="upload-progress-${id}">0%</span>`

        this.submitButtonTarget.disabled = true
        this.submitButtonTarget.value = "Uploading"
    }

    uploadStart(event) {
        const { id } = event.detail
        const element = document.getElementById(`direct-upload-${id}`)
        element.classList.remove("direct-upload--pending")
    }

    uploadProgress(event) {
        const { id, progress } = event.detail
        const progressElement = document.getElementById(`direct-upload-progress-${id}`)
        progressElement.style.width = `${progress}%`
        document.getElementById(`upload-progress-${id}`).innerText = `${Math.round(progress)}%`
    }

    uploadError(event) {
        event.preventDefault()
        const { id, error } = event.detail
        const element = document.getElementById(`direct-upload-${id}`)
        element.classList.add("direct-upload--error border-rose-600")
        element.setAttribute("title", error)
    }

    uploadEnd(event) {
        const { id } = event.detail
        const element = document.getElementById(`direct-upload-${id}`)
        element.classList.add("direct-upload--complete")
    }
    disconnect() {
        this.element.removeEventListener("direct-upload:initialize", event => this.uploadInitialize(event))
        this.element.removeEventListener("direct-upload:start", event => this.uploadStart(event))
        this.element.removeEventListener("direct-upload:progress", event => this.uploadStart(event))
        this.element.removeEventListener("direct-upload:error", event => this.uploadProgress(event))
        this.element.removeEventListener("direct-upload:end", event => this.uploadEnd(event))
    }
}
