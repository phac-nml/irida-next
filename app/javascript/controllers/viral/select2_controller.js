import { Controller } from "@hotwired/stimulus";

/**
 * 🌟✨ Select2Controller ✨🌟
 *
 * 🧩 A custom dropdown selector with keyboard navigation and search functionality.
 * 🪄 Implements a lightweight alternative to Select2 using Flowbite & Stimulus.
 *
 * 📝 Features:
 * - ⬆️⬇️ Keyboard navigation (up/down/enter/escape)
 * - 🔍 Search filtering
 * - ♿ Accessible focus management
 * - 📐 Dropdown positioning
 */
export default class Select2Controller extends Controller {
  /**
   * 🎯 Stimulus Targets 🎯
   * 🏷️ Define all DOM elements that this controller interacts with
   */
  static targets = [
    "input", // 📝 Text input for searching/displaying selected value
    "hidden", // 🙈 Hidden input that stores the actual value
    "dropdown", // 📦 Dropdown container
    "scroller", // 📜 Scrollable container for items
    "item", // 🔘 Individual selectable items
    "empty", // 🕸️ Empty state message when no results found
    "submitButton", // 🖱️ Submit button for form submission
  ];

  /**
   * 🔒 Private Properties 🔒
   * 🛡️ Using private class fields for encapsulation
   */
  #isItemSelected = false; // 🚩 Tracks if an item has been selected
  #cachedInputValue = ""; // 💾 Stores the last valid input value
  #currentItemIndex = -1; // 🔍 Tracks current position during keyboard navigation
  #dropdown = null; // 📦 Reference to the dropdown instance
  #boundHandlers = {}; // 🔗 Store bound event handlers for cleanup

  /**
   * ⌨️ Keyboard Navigation Constants ⌨️
   * 🔢 Defining key codes for better readability
   */
  static #KEY_CODES = {
    ARROW_DOWN: "ArrowDown", // ⬇️
    ARROW_UP: "ArrowUp", // ⬆️
    ENTER: "Enter", // ⏎
    ESCAPE: "Escape", // 🏃‍♂️
  };

  /**
   * 🚀 Lifecycle Methods 🚀
   * 🕰️ Methods that run at specific points in the controller's lifecycle
   */

  /**
   * 🔌 connect() 🔌
   * 🟢 Initialize controller when connected to DOM
   * 🛠️ Sets up the dropdown and event listeners
   */
  connect() {
    try {
      this.#validateTargets(); // ✅ Ensure all required targets exist
      this.#initializeDropdown(); // 🛠️ Setup dropdown
      this.#setDefaultSelection(); // 🏷️ Set initial selection

      // 🔗 Bind and add focusout event handler for dropdown
      this.#boundHandlers.dropdownFocusOut =
        this.#handleDropdownFocusOut.bind(this);
      this.dropdownTarget.addEventListener(
        "focusout",
        this.#boundHandlers.dropdownFocusOut,
      );

      // 🟢 Mark controller as connected for parent controllers
      this.element.setAttribute("data-controller-connected", "true");

      console.debug("🔌 Select2Controller connected", {
        element: this.element,
      });
    } catch (error) {
      console.error("❌ Error connecting Select2Controller:", error);
      this.#handleError(error, "connect");
    }
  }

  /**
   * 🔌 disconnect() 🔌
   * 🔴 Clean up when controller is disconnected from DOM
   * 🧹 Removes event listeners to prevent memory leaks
   */
  disconnect() {
    try {
      // 🔗 Remove event listeners
      if (this.#boundHandlers.dropdownFocusOut) {
        this.dropdownTarget.removeEventListener(
          "focusout",
          this.#boundHandlers.dropdownFocusOut,
        );
      }

      // 💣 Destroy dropdown instance
      if (this.#dropdown) {
        this.#dropdown.hide();
        this.#dropdown = null;
      }

      console.debug("🔌 Select2Controller disconnected", {
        element: this.element,
      });
    } catch (error) {
      console.error("❌ Error disconnecting Select2Controller:", error);
    }
  }

  /**
   * 🎮 Public Action Methods 🎮
   * 🕹️ Methods that can be called directly from the DOM
   */

  /**
   * 🖱️ select(event) 🖱️
   * 🎯 Handle item selection (click or keyboard)
   *
   * @param {Event} event - 🏷️ The triggering event (click or keydown)
   */
  select(event) {
    try {
      const { label, value } = event.target.dataset;

      // 🛑 Validate selection data
      if (!label || !value) {
        throw new Error(
          "❗ Invalid selection: missing label or value. Ensure Tailwind class `pointer-events-none` is not applied to any element in option.",
        );
      }

      // ✅ Update selection and UI state
      this.#updateSelection(value, label);
      this.#isItemSelected = true;
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.disabled = false;
      }

      // 👋 Hide dropdown and focus input
      if (this.#dropdown) {
        this.#dropdown.hide();
      }
      this.inputTarget.focus();
    } catch (error) {
      console.error("❌ Error in select action:", error);
      this.#handleError(error, "select");
    }
  }

  /**
   * ⌨️ keydown(event) ⌨️
   * 🎹 Handle keyboard navigation for dropdown
   *
   * @param {KeyboardEvent} event - ⌨️ The keyboard event
   */
  keydown(event) {
    try {
      // ⛔ Only process navigation keys
      if (!Object.values(Select2Controller.#KEY_CODES).includes(event.key)) {
        return;
      }

      // 🚫 Prevent default browser behavior
      event.preventDefault();
      event.stopPropagation();

      switch (event.key) {
        case Select2Controller.#KEY_CODES.ARROW_DOWN: // ⬇️
          this.#navigateItems(1);
          break;
        case Select2Controller.#KEY_CODES.ARROW_UP: // ⬆️
          this.#navigateItems(-1);
          break;
        case Select2Controller.#KEY_CODES.ESCAPE: // 🏃‍♂️
          this.#resetInput();
          break;
        case Select2Controller.#KEY_CODES.ENTER: // ⏎
          if (event.target.nodeName === "INPUT") {
            // 👁️ Show dropdown when pressing enter in input field
            if (this.#dropdown) this.#dropdown.show();
          } else {
            // 🖱️ Select item when pressing enter on an item
            this.select(event);
          }
          break;
      }
    } catch (error) {
      console.error("❌ Error in keydown handling:", error);
      this.#handleError(error, "keydown");
    }
  }

  /**
   * 🔍 input() 🔍
   * 🧹 Handle input filtering for dropdown items
   */
  input() {
    try {
      const query = this.inputTarget.value.toLowerCase().trim();
      let visibleItemCount = 0;

      // 🧹 Reset selection state when input changes
      this.#isItemSelected = false;
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.disabled = true;
      }

      // 🔎 Filter items based on query
      this.itemTargets.forEach((item) => {
        const text = item.textContent.toLowerCase() || "";
        if (text.includes(query)) {
          item.parentNode.classList.remove("hidden");
          visibleItemCount++;
        } else {
          item.parentNode.classList.add("hidden");
        }
      });

      // 🔄 Reset navigation index
      this.#currentItemIndex = -1;

      // 🖼️ Update UI based on results
      if (visibleItemCount > 0) {
        if (this.#dropdown) this.#dropdown.show();
        this.emptyTarget.classList.add("hidden");
        this.scrollerTarget.scrollTop = 0;
      } else {
        this.emptyTarget.classList.remove("hidden");
      }
    } catch (error) {
      console.error("❌ Error in input filtering:", error);
      this.#handleError(error, "input");
    }
  }

  /**
   * 🔒 Private Helper Methods 🔒
   * 🧰 Internal methods to support the controller's functionality
   */

  /**
   * 🧭 #navigateItems(direction) 🧭
   * 🚶‍♂️ Moves focus up or down through the filtered items
   *
   * @param {number} direction - ➡️ Direction to move (1 for down, -1 for up)
   * @private
   */
  #navigateItems(direction) {
    try {
      // 👀 Get only visible items
      const visibleItems = this.itemTargets.filter(
        (item) => !item.parentNode.classList.contains("hidden"),
      );

      if (visibleItems.length === 0) return;

      // 🔢 Calculate new index
      const newIndex = this.#calculateNewIndex(direction, visibleItems.length);

      // 🏁 Handle navigation to input field
      if (newIndex < 0) {
        this.inputTarget.focus();
        return;
      }

      // 🎯 Focus the new item
      if (newIndex < visibleItems.length) {
        visibleItems[newIndex].focus();
        this.#currentItemIndex = newIndex;
        this.#ensureItemVisible(visibleItems[newIndex]);
      }
    } catch (error) {
      console.error("❌ Error navigating items:", error);
    }
  }

  /**
   * 🔢 #calculateNewIndex(direction, itemCount) 🔢
   * 🧮 Determines the next index based on current position and direction
   *
   * @param {number} direction - ➡️ Direction to move (1 for down, -1 for up)
   * @param {number} itemCount - 🔢 Total number of visible items
   * @returns {number} - 🆕 The new index
   * @private
   */
  #calculateNewIndex(direction, itemCount) {
    if (itemCount === 0) return -1;
    if (this.#currentItemIndex === -1 && direction === -1) return -1;
    if (this.#currentItemIndex === -1 && direction === 1) return 0;

    const newIndex = this.#currentItemIndex + direction;
    if (newIndex >= itemCount) return this.#currentItemIndex; // 🚫 Don't go past last item
    if (newIndex < -1) return -1; // 🚫 Don't go before input

    return newIndex;
  }

  /**
   * 📜 #ensureItemVisible(item) 📜
   * 👁️ Scrolls the container if needed to show the focused item
   *
   * @param {HTMLElement} item - 🎯 The item to make visible
   * @private
   */
  #ensureItemVisible(item) {
    if (!this.scrollerTarget || !item) return;

    const container = this.scrollerTarget;
    const containerRect = container.getBoundingClientRect();
    const itemRect = item.getBoundingClientRect();

    // 👀 Check if item is outside visible area
    if (itemRect.bottom > containerRect.bottom) {
      container.scrollTop += itemRect.bottom - containerRect.bottom;
    } else if (itemRect.top < containerRect.top) {
      container.scrollTop -= containerRect.top - itemRect.top;
    }
  }

  /**
   * 🛠️ #initializeDropdown() 🛠️
   * 🏗️ Sets up the Flowbite dropdown component
   * @private
   */
  #initializeDropdown() {
    try {
      if (typeof Dropdown !== "function") {
        throw new Error(
          "❗ Flowbite Dropdown class not found. Make sure Flowbite JS is loaded.",
        );
      }

      // 🏗️ Create dropdown instance
      this.#dropdown = new Dropdown(this.dropdownTarget, this.inputTarget, {
        placement: "bottom",
        triggerType: "click",
        offsetSkidding: 0,
        offsetDistance: 10,
        delay: 300,
        onShow: () => {
          // ↔️ Match dropdown width to input width
          this.dropdownTarget.style.width = `${this.inputTarget.offsetWidth}px`;
        },
        onHide: () => {
          // 🧹 Clear input if no item was selected
          if (!this.#isItemSelected) {
            this.#setInputTargetValueFromCache();
          }
        },
      });
    } catch (error) {
      console.error("❌ Error initializing dropdown:", error);
      this.#handleError(error, "initializeDropdown");
    }
  }

  /**
   * 🏷️ #setDefaultSelection() 🏷️
   * 🏁 Sets initial selection based on input value
   * @private
   */
  #setDefaultSelection() {
    try {
      if (!this.inputTarget.value) return;

      const query = this.inputTarget.value;
      let matched = false;

      // 🔍 Try to find matching item
      for (const item of this.itemTargets) {
        const { value, label } = item.dataset;
        if (value === query) {
          this.#isItemSelected = true;
          this.#updateSelection(value, label);
          matched = true;
          break;
        }
      }

      // ❗ If no match found but input has value, cache it
      if (!matched && this.inputTarget.value) {
        throw new Error(
          "❗ No matching item found for the input value. Please check your data.",
        );
      }
    } catch (error) {
      console.error("❌ Error setting default selection:", error);
      this.#handleError(error, "setDefaultSelection");
    }
  }

  /**
   * 🖋️ #updateSelection(value, label) 🖋️
   * ✍️ Sets the display text and actual value
   *
   * @param {string} value - 🏷️ The actual value
   * @param {string} label - 📝 The display text
   * @private
   */
  #updateSelection(value, label) {
    try {
      if (!label || !value) {
        throw new Error("❗ Cannot update selection with empty values");
      }

      this.inputTarget.value = label;
      this.#cachedInputValue = value;
      this.hiddenTarget.value = value;
    } catch (error) {
      console.error("❌ Error updating selection:", error);
      this.#handleError(error, "updateSelection");
    }
  }

  /**
   * 🔄 #resetInput() 🔄
   * ♻️ Restores input to last valid selection
   * @private
   */
  #resetInput() {
    try {
      if (this.#dropdown) this.#dropdown.hide();
      this.#setInputTargetValueFromCache();
      this.inputTarget.focus();
      this.inputTarget.select();
    } catch (error) {
      console.error("❌ Error resetting input:", error);
    }
  }

  /**
   * 🔒 #handleDropdownFocusOut(event) 🔒
   * 🚪 Closes dropdown when focus leaves the component
   *
   * @param {FocusEvent} event - 👁️ The focus event
   * @private
   */
  #handleDropdownFocusOut(event) {
    try {
      // 🚪 Only hide if focus moved outside the dropdown
      if (!this.dropdownTarget.contains(event.relatedTarget)) {
        if (this.#dropdown) this.#dropdown.hide();
      }
    } catch (error) {
      console.error("❌ Error handling focus out:", error);
    }
  }

  /**
   * ✅ #validateTargets() ✅
   * 🕵️‍♂️ Ensures all required DOM elements are present
   * @private
   */
  #validateTargets() {
    const missingTargets = [];
    if (!this.hasInputTarget) missingTargets.push("input");
    if (!this.hasHiddenTarget) missingTargets.push("hidden");
    if (!this.hasDropdownTarget) missingTargets.push("dropdown");
    if (!this.hasScrollerTarget) missingTargets.push("scroller");

    if (missingTargets.length > 0) {
      throw new Error(
        `❗ Missing required targets: ${missingTargets.join(", ")}`,
      );
    }
  }

  /**
   * ❌ #handleError(error, source) ❌
   * 🚨 Centralized error handling
   *
   * @param {Error} error - 🛑 The error object
   * @param {string} source - 🏷️ Where the error occurred
   * @private
   */
  #handleError(error, source) {
    console.error(`❌ Select2Controller error in ${source}:`, error);
  }

  #setInputTargetValueFromCache() {
    // 🏷️ Find item label from cached value
    const foundItem = this.itemTargets.find(
      (item) => item.dataset.value === this.#cachedInputValue,
    );
    this.inputTarget.value = foundItem ? foundItem.dataset.label : "";
  }
}
