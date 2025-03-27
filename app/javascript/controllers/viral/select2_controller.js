import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "hidden", "dropdown", "scroller", "item", "empty"];
  #found = false;
  #storedInputvalue = "";

  connect() {
    this.dropdown = new Dropdown(this.dropdownTarget, this.inputTarget, {
      placement: "bottom",
      triggerType: "click",
      offsetSkidding: 0,
      offsetDistance: 10,
      delay: 300,
      onShow: () => {
        this.dropdownTarget.style.width = `${this.inputTarget.offsetWidth}px`;
      },
      onHide: () => {
        if (!this.#found) {
          this.inputTarget.value = "";
        }
      },
    });

    this.#setDefault();
    this.element.setAttribute("data-controller-connected", "true");
    this.currentIndex = -1; // Initialize the index for navigation

    this.dropdownTarget.addEventListener(
      "focusout",
      this.handleTriggerFocusOut.bind(this),
    );
  }

  disconnect() {
    this.dropdownTarget.removeEventListener(
      "focusout",
      this.handleTriggerFocusOut.bind(this),
    );
  }

  focus() {
    this.#filterItems();
  }

  select(event) {
    if (event.params.primary) {
      // This handles when the item is clicked
      this.inputTarget.value = event.params.primary;
      this.#storedInputvalue = event.params.primary;
      this.hiddenTarget.value = event.params.value;
    } else {
      // This handles when enter is pressed on a list item
      this.inputTarget.value =
        event.target.dataset["viral-Select2PrimaryParam"];
      this.#storedInputvalue =
        event.target.dataset["viral-Select2PrimaryParam"];
      this.hiddenTarget.value = event.target.dataset["viral-Select2ValueParam"];
    }
    this.#found = true;
    this.dropdown.hide();
    this.inputTarget.focus();
  }

  keydown(event) {
    if (event.key === "Tab") {
      // Allow Tab to work normally
      return;
    }

    // For all other keys, prevent default behavior
    event.preventDefault();
    event.stopPropagation();

    switch (event.key) {
      case "ArrowDown":
        this.#navigate(1);
        break;
      case "ArrowUp":
        this.#navigate(-1);
        break;
      case "Escape":
        this.dropdown.hide();
        this.inputTarget.value = this.#storedInputvalue;
        this.inputTarget.focus();
        this.inputTarget.select();
        break;
      case "Enter":
        if (!this.dropdown.isVisible()) {
          this.dropdown.show();
          return;
        } else if (this.currentIndex >= 0) {
          this.select(event);
        }
        break;
      default:
        this.#filterItems();
        break;
    }
  }

  keyboardQuery(event) {
    console.log("keyboardQuery");
    const visible = this.itemTargets.filter(
      (item) => !item.parentNode.classList.contains("hidden"),
    );
    if (visible.length === 1) {
      this.select({
        params: {
          primary: visible[0].dataset["viral-Select2PrimaryParam"],
          value: visible[0].dataset["viral-Select2ValueParam"],
        },
      });
      this.inputTarget.focus();
      this.inputTarget.select();
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
      this.currentIndex = newIndex;
    }
  }

  #filterItems() {
    // const query = this.inputTarget.value.toLowerCase();
    // let count = 0;
    // this.itemTargets.forEach((item) => {
    //   const value = item.dataset;
    //   if (
    //     value["viral-Select2PrimaryParam"].toLowerCase().includes(query) ||
    //     value["viral-Select2SecondaryParam"].toLowerCase().includes(query)
    //   ) {
    //     item.parentNode.classList.remove("hidden");
    //     count++;
    //   } else {
    //     item.parentNode.classList.add("hidden");
    //   }
    // });
    // // Reset the index if the items are filtered
    // this.currentIndex = -1;
    // if (count > 0) {
    //   this.dropdown.show();
    //   this.emptyTarget.classList.add("hidden");
    //   this.scrollerTarget.scrollTop = 0;
    // } else {
    //   this.emptyTarget.classList.remove("hidden");
    // }
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

  #setDefault() {
    if (this.inputTarget.value) {
      const query = this.inputTarget.value.toLowerCase();

      this.itemTargets.forEach((item) => {
        const value = item.dataset;
        if (value["viral-Select2ValueParam"].toLowerCase() === query) {
          this.#found = true;
          this.inputTarget.value = value["viral-Select2PrimaryParam"];
          this.#storedInputvalue = value["viral-Select2PrimaryParam"];
          this.hiddenTarget.value = value["viral-Select2ValueParam"];
        }
      });
    }
  }

  handleTriggerFocusOut(event) {
    if (!this.dropdownTarget.contains(event.relatedTarget)) {
      this.dropdown.hide();
    }
  }
}
