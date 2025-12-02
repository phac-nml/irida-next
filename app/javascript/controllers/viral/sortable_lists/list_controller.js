import { Controller } from "@hotwired/stimulus";
import { Sortable } from "sortablejs";

export default class extends Controller {
  static targets = ["counter", "currentCount"];

  static values = {
    groupName: String,
    maxItems: Number,
    scrollSensitivity: {
      type: Number,
      default: 50,
    },
    scrollSpeed: {
      type: Number,
      default: 8,
    },
  };

  connect() {
    this.sortable = new Sortable(this.element, {
      scroll: true,
      scrollSensitivity: this.scrollSensitivityValue, // The number of px from div edge where scroll begins
      scrollSpeed: this.scrollSpeedValue,
      bubbleScroll: true,
      group: this.groupNameValue,
      animation: 100,
      onMove: (evt) => {
        return this.#canAcceptItem(evt.to);
      },
      onAdd: () => {
        this.#updateCounter();
        this.#enforceMaxItemsLimit();
      },
      onRemove: () => {
        this.#updateCounter();
      },
      onSort: () => {
        this.#updateCounter();
      },
      onEnd: () => {
        // Enforce limit after any drag operation completes
        this.#enforceMaxItemsLimit();
      },
    });

    // Initialize counter on connect
    this.#updateCounter();
    // Enforce limit on initial connect
    this.#enforceMaxItemsLimit();
  }

  #canAcceptItem(targetList) {
    // If no max items set, always allow
    if (!this.hasMaxItemsValue) {
      return true;
    }

    // Check if the target list has reached its maximum
    const currentItemCount = targetList.querySelectorAll("li").length;
    return currentItemCount < this.maxItemsValue;
  }

  #updateCounter() {
    if (this.hasCurrentCountTarget) {
      const currentCount = this.element.querySelectorAll("li").length;
      this.currentCountTarget.textContent = currentCount;
    }
  }

  #enforceMaxItemsLimit() {
    if (!this.hasMaxItemsValue) {
      return;
    }

    const currentItems = Array.from(this.element.querySelectorAll("li"));
    const maxItemsInt = this.maxItemsValue;

    if (currentItems.length > maxItemsInt) {
      // Find the parent available list to move excess items to
      // This assumes the available list is in the same group
      const availableList = document.querySelector(
        `[data-viral--sortable-lists--list-group-name-value="${this.groupNameValue}"]:not([id="${this.element.id}"])`,
      );

      if (availableList) {
        // Move excess items to available list
        const excessItems = currentItems.slice(maxItemsInt);
        excessItems.forEach((item) => {
          availableList.appendChild(item);
        });
        this.#updateCounter();
      }
    }
  }
}
