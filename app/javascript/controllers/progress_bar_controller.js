import { Controller } from "@hotwired/stimulus";

// A progress bar will accept itemsToComplete to calculate the ongoing percentage of completed tasks (ie: samples to copy)
// Each time a task is completed (such as one sample is copied), a hidden div's (progressIndexTarget) content will be
// updated with the new value equaling the number of ongoing completed tasks (total samples copied so far).
// The mutationObserver will observe this content change, and the progress bar values will be updated accordingly
export default class extends Controller {
  static values = {
    itemsToComplete: 0,
    completedCount: 0,
  };
  static targets = ["progress", "progressText", "progressIndex"];
  connect() {
    // warns user about refreshing page during action progress
    window.addEventListener("beforeunload", this.beforeUnloadHandler);
    this.observer = new MutationObserver((mutationsList, _observer) => {
      for (let mutation of mutationsList) {
        if (mutation.type === "childList") {
          this.updateProgress();
        }
      }
    });

    this.observer.observe(this.element, { childList: true });
  }

  disconnect() {
    window.removeEventListener("beforeunload", this.beforeUnloadHandler);
  }

  beforeUnloadHandler(event) {
    event.preventDefault();
  }

  updateProgress() {
    this.completedCountValue = parseInt(this.progressIndexTarget.textContent);
    console.log(this.completedCountValue);
    let progress = (this.completedCountValue / this.itemsToCompleteValue) * 100;
    // in case of rounding errors
    if (progress > 100) {
      progress = 100;
    }
    this.progressTarget.style.width = `${progress}%`;
    this.progressTextTarget.innerHTML = `${Math.round(progress)}%`;
  }
}
