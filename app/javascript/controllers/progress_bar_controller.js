import { Controller } from "@hotwired/stimulus";

// A progress bar will accept itemsToComplete to calculate the ongoing percentage of completed tasks (ie: samples to copy)
// Each time a task is completed (one sample is copied), an empty div will be appended and observed via the MutationObserver,
// and completedCount will be incremented by 1. This then updates the progress bar and percentage text.
// eg: if there are 100 samples to copy, itemsToComplete = 100, and we'll observe 100 empty divs appended, each increasing
// completedCount by 1 and increasing the progress vars.
export default class extends Controller {
  static values = {
    itemsToComplete: 0,
    completedCount: 0,
  };
  static targets = ["progress", "progressText"];
  connect() {
    this.observer = new MutationObserver((mutationsList, _observer) => {
      for (let mutation of mutationsList) {
        if (mutation.type === "childList") {
          this.increment();
        }
      }
    });

    this.observer.observe(this.element, { childList: true });
  }

  increment() {
    this.completedCountValue++;
    this.updateProgress();
  }

  updateProgress() {
    let progress = (this.completedCountValue / this.itemsToCompleteValue) * 100;
    // avoids rounding errors
    if (progress > 100) {
      progress = 100;
    }
    this.progressTarget.style.width = `${progress}%`;
    this.progressTextTarget.innerHTML = `${Math.round(progress)}%`;
  }
}
