import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="progress-bar"
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
    if (progress > 100) {
      progress = 100;
    }
    this.progressTarget.style.width = `${progress}%`;
    this.progressTextTarget.innerHTML = `${Math.round(progress)}%`;
  }
}
