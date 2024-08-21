import { Controller } from "@hotwired/stimulus";
import { Dropdown } from "flowbite";

export default class extends Controller {
  static targets = ["input", "hidden", "dropdown", "scroller", "item"];
  #found = false;

  connect() {
    this.dropdown = new Dropdown(this.dropdownTarget, this.inputTarget, {
      triggerType: "none",
      offsetSkidding: 0,
      offsetDistance: 0,
      placement: "bottom-start",
      onHide: () => {
        if (!this.#found) {
          this.inputTarget.value = "";
        }
      },
    });

    this.element.setAttribute("data-controller-connected", "true");
    this.currentIndex = -1; // Initialize the index for navigation
  }

  focus() {
    this.#filterItems();
  }

  select(event) {
    console.log(event);
    this.#found = true;
    this.inputTarget.value = event.params.primary;
    this.hiddenTarget.value = event.params.value;
    this.dropdown.hide();
  }

  keydown(event) {
    switch (event.key) {
      case "ArrowDown":
        this.#navigate(1);
        break;
      case "ArrowUp":
        this.#navigate(-1);
        break;
      case "Enter":
        if (this.currentIndex >= 0) {
          this.select({ target: this.itemTargets[this.currentIndex] });
          this.#found = true;
        }
        break;
      default:
        this.#filterItems();
        break;
    }
  }

  #navigate(direction) {
    if (this.itemTargets.length === 0) return;
    const visible = this.itemTargets.filter(
      (item) => !item.parentNode.classList.contains("hidden"),
    );
    const newIndex = this.#newIndex(direction);

    // If the current index is 0, and the direction is -1, select the input
    if (newIndex < 0) {
      this.inputTarget.focus();
      return;
    }

    if (newIndex < visible.length) {
      visible[newIndex].focus();
    }
    this.currentIndex = newIndex;
  }

  #filterItems() {
    const query = this.inputTarget.value.toLowerCase();
    let count = 0;

    this.itemTargets.forEach((item) => {
      const value = item.dataset;
      if (
        value["viral-Select2PrimaryParam"].toLowerCase().includes(query) ||
        value["viral-Select2SecondaryParam"].toLowerCase().includes(query)
      ) {
        item.parentNode.classList.remove("hidden");
        count++;
      } else {
        item.parentNode.classList.add("hidden");
      }
    });

    // Reset the index if the items are filtered
    this.currentIndex = -1;

    if (count > 0) {
      this.dropdown.show();
      this.scrollerTarget.scrollTop = 0;
    } else {
      this.dropdown.hide();
    }
  }

  #newIndex(direction) {
    if (this.currentIndex === -1 && direction === -1) {
      return -1;
    } else if (this.currentIndex + direction === this.itemTargets.length) {
      return this.currentIndex;
    } else {
      return this.currentIndex + direction;
    }
  }
}
