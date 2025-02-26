import { Controller } from "@hotwired/stimulus";

// A progress bar will accept itemsToComplete to calculate the ongoing percentage of completed tasks (ie: samples to copy)
// Each time 50 tasks are completed (50 samples are copied) or the final task is completed (sample 101 of 101),
// an empty div will be appended and observed via the MutationObserver,
// and completedCount will be incremented by 50. This then updates the progress bar and percentage text.
// eg: if there are 101 samples to copy, itemsToComplete = 101, and we'll observe 3 empty divs appended
// (at 50, 100, and 101) and increasing the progress variables accordingly.
export default class extends Controller {
  static values = {
    itemsToComplete: 0,
    completedCount: 0,
  };
  static targets = ["progress", "progressText"];
  connect() {
    // warns user about refreshing page during action progress
    window.addEventListener("beforeunload", this.beforeUnloadHandler);
    this.observer = new MutationObserver((mutationsList, _observer) => {
      for (let mutation of mutationsList) {
        if (mutation.type === "childList") {
          this.increment();
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

  increment() {
    this.completedCountValue += 50;
    this.updateProgress();
  }

  updateProgress() {
    let progress = (this.completedCountValue / this.itemsToCompleteValue) * 100;
    // our progress percent logic likely has the 100% (completed) state above 100%, so we adjust it to 100
    if (progress > 100) {
      progress = 100;
    }
    this.progressTarget.style.width = `${progress}%`;
    this.progressTextTarget.innerHTML = `${Math.round(progress)}%`;
  }
}
