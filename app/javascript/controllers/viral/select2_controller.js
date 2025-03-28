import { Controller } from "@hotwired/stimulus";

/**
 * 🌟 Select2Controller 🌟
 *
 * A custom dropdown selector with keyboard navigation and search functionality.
 * This controller implements a lightweight alternative to the Select2 library.
 *
 * 📋 Features:
 * - Keyboard navigation (up/down/enter/escape)
 * - Search filtering
 * - Accessible focus management
 * - Dropdown positioning
 *
 * @author IRIDA Team
 * @version 1.0.0
 */
export default class Select2Controller extends Controller {
  /**
   * 🎯 Stimulus Targets
   * Define all DOM elements that this controller needs to interact with
   */
  static targets = [
    "input", // 📝 Text input for searching/displaying selected value
    "hidden", // 🙈 Hidden input that stores the actual value
    "dropdown", // 📦 Dropdown container
    "scroller", // 📜 Scrollable container for items
    "item", // 🔘 Individual selectable items
    "empty", // 🕸️ Empty state message when no results found
  ];

  /**
   * 🔒 Private Properties
   * Using private class fields for better encapsulation
   */
  #isItemSelected = false; // 🚩 Flag to track if an item has been selected
  #cachedInputValue = ""; // 💾 Stores the last valid input value
  #currentItemIndex = -1; // 🔍 Tracks current position during keyboard navigation
  #dropdown = null; // 📦 Reference to the dropdown instance
  #boundHandlers = {}; // 🔗 Store bound event handlers for cleanup

  /**
   * ⌨️ Keyboard Navigation Constants
   * Defining key codes for better readability
   */
  static #KEY_CODES = {
    ARROW_DOWN: "ArrowDown",
    ARROW_UP: "ArrowUp",
    ENTER: "Enter",
    ESCAPE: "Escape",
  };

  /**
   * 🚀 Lifecycle Methods
   * Methods that run at specific points in the controller's lifecycle
   */

  /**
   * 🔌 Initialize controller when connected to DOM
   * Sets up the dropdown and event listeners
   */
  connect() {
    try {
      // Verify required targets exist
      this.#validateTargets();

      // Initialize dropdown and default selection
      this.#initializeDropdown();
      this.#setDefaultSelection();

      // Set up event handlers with proper binding
      this.#boundHandlers.dropdownFocusOut =
        this.#handleDropdownFocusOut.bind(this);
      this.dropdownTarget.addEventListener(
        "focusout",
        this.#boundHandlers.dropdownFocusOut,
      );

      // Mark controller as connected for potential parent controllers
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
   * 🔌 Clean up when controller is disconnected from DOM
   * Removes event listeners to prevent memory leaks
   */
  disconnect() {
    try {
      // Remove event listeners
      if (this.#boundHandlers.dropdownFocusOut) {
        this.dropdownTarget.removeEventListener(
          "focusout",
          this.#boundHandlers.dropdownFocusOut,
        );
      }

      // Destroy dropdown instance
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
   * 🎮 Public Action Methods
   * Methods that can be called directly from the DOM
   */

  /**
   * 🖱️ Handle item selection
   * Called when an item is clicked or selected with keyboard
   *
   * @param {Event} event - The triggering event (click or keydown)
   */
  select(event) {
    try {
      let primary, value;

      if (event.type === "click") {
        // Handle click selection
        primary = event.params.primary;
        value = event.params.value;
      } else if (event.type === "keydown" && event.key === "Enter") {
        // Handle keyboard selection
        primary = event.target.dataset["viral-Select2PrimaryParam"];
        value = event.target.dataset["viral-Select2ValueParam"];
      } else {
        // Invalid event type
        return;
      }

      // Validate selection data
      if (!primary || !value) {
        throw new Error("Invalid selection: missing primary or value data");
      }

      // Update selection and UI state
      this.#updateSelection(primary, value);
      this.#isItemSelected = true;

      // Hide dropdown and focus input
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
   * ⌨️ Handle keyboard navigation
   * Manages arrow keys, enter, and escape for dropdown navigation
   *
   * @param {KeyboardEvent} event - The keyboard event
   */
  keydown(event) {
    try {
      // Only process navigation keys
      if (!Object.values(Select2Controller.#KEY_CODES).includes(event.key)) {
        this.input();
        return;
      }

      // Prevent default browser behavior for these keys
      event.preventDefault();
      event.stopPropagation();

      switch (event.key) {
        case Select2Controller.#KEY_CODES.ARROW_DOWN:
          this.#navigateItems(1);
          break;

        case Select2Controller.#KEY_CODES.ARROW_UP:
          this.#navigateItems(-1);
          break;

        case Select2Controller.#KEY_CODES.ESCAPE:
          this.#resetInput();
          break;

        case Select2Controller.#KEY_CODES.ENTER:
          if (event.target.nodeName === "INPUT") {
            // Show dropdown when pressing enter in input field
            if (this.#dropdown) this.#dropdown.show();
          } else {
            // Select item when pressing enter on an item
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
   * 🔍 Handle input filtering
   * Filters dropdown items based on input text
   */
  input() {
    try {
      const query = this.inputTarget.value.toLowerCase().trim();
      let visibleItemCount = 0;

      // Reset selection state when input changes
      this.#isItemSelected = false;

      // Filter items based on query
      this.itemTargets.forEach((item) => {
        // Get search data from item
        const primary = (
          item.dataset["viral-Select2PrimaryParam"] || ""
        ).toLowerCase();
        const secondary = (
          item.dataset["viral-Select2SecondaryParam"] || ""
        ).toLowerCase();

        // Show item if it matches query
        if (primary.includes(query) || secondary.includes(query)) {
          item.parentNode.classList.remove("hidden");
          visibleItemCount++;
        } else {
          item.parentNode.classList.add("hidden");
        }
      });

      // Reset navigation index
      this.#currentItemIndex = -1;

      // Update UI based on results
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
   * 🔒 Private Helper Methods
   * Internal methods to support the controller's functionality
   */

  /**
   * 🧭 Navigate through visible items
   * Moves focus up or down through the filtered items
   *
   * @param {number} direction - Direction to move (1 for down, -1 for up)
   * @private
   */
  #navigateItems(direction) {
    try {
      // Get only visible items
      const visibleItems = this.itemTargets.filter(
        (item) => !item.parentNode.classList.contains("hidden"),
      );

      if (visibleItems.length === 0) return;

      // Calculate new index
      const newIndex = this.#calculateNewIndex(direction, visibleItems.length);

      // Handle navigation to input field
      if (newIndex < 0) {
        this.inputTarget.focus();
        return;
      }

      // Focus the new item
      if (newIndex < visibleItems.length) {
        visibleItems[newIndex].focus();
        this.#currentItemIndex = newIndex;

        // Ensure item is visible in scroll container
        this.#ensureItemVisible(visibleItems[newIndex]);
      }
    } catch (error) {
      console.error("❌ Error navigating items:", error);
    }
  }

  /**
   * 🔢 Calculate new index for navigation
   * Determines the next index based on current position and direction
   *
   * @param {number} direction - Direction to move (1 for down, -1 for up)
   * @param {number} itemCount - Total number of visible items
   * @returns {number} - The new index
   * @private
   */
  #calculateNewIndex(direction, itemCount) {
    // Handle edge cases
    if (itemCount === 0) return -1;
    if (this.#currentItemIndex === -1 && direction === -1) return -1;
    if (this.#currentItemIndex === -1 && direction === 1) return 0;

    // Calculate new index with bounds checking
    const newIndex = this.#currentItemIndex + direction;
    if (newIndex >= itemCount) return this.#currentItemIndex; // Don't go past last item
    if (newIndex < -1) return -1; // Don't go before input

    return newIndex;
  }

  /**
   * 📜 Ensure the item is visible in the scroll container
   * Scrolls the container if needed to show the focused item
   *
   * @param {HTMLElement} item - The item to make visible
   * @private
   */
  #ensureItemVisible(item) {
    if (!this.scrollerTarget || !item) return;

    const container = this.scrollerTarget;
    const containerRect = container.getBoundingClientRect();
    const itemRect = item.getBoundingClientRect();

    // Check if item is outside visible area
    if (itemRect.bottom > containerRect.bottom) {
      // Item is below visible area
      container.scrollTop += itemRect.bottom - containerRect.bottom;
    } else if (itemRect.top < containerRect.top) {
      // Item is above visible area
      container.scrollTop -= containerRect.top - itemRect.top;
    }
  }

  /**
   * 🛠️ Initialize dropdown
   * Sets up the Flowbite dropdown component
   * @private
   */
  #initializeDropdown() {
    try {
      // Check if Dropdown class exists
      if (typeof Dropdown !== "function") {
        throw new Error(
          "Flowbite Dropdown class not found. Make sure Flowbite JS is loaded.",
        );
      }

      // Create dropdown instance
      this.#dropdown = new Dropdown(this.dropdownTarget, this.inputTarget, {
        placement: "bottom",
        triggerType: "click",
        offsetSkidding: 0,
        offsetDistance: 10,
        delay: 300,
        onShow: () => {
          // Match dropdown width to input width
          this.dropdownTarget.style.width = `${this.inputTarget.offsetWidth}px`;
        },
        onHide: () => {
          // Clear input if no item was selected
          if (!this.#isItemSelected) {
            this.inputTarget.value = this.#cachedInputValue || "";
          }
        },
      });
    } catch (error) {
      console.error("❌ Error initializing dropdown:", error);
      this.#handleError(error, "initializeDropdown");
    }
  }

  /**
   * 🏷️ Set default selection
   * Sets initial selection based on input value
   * @private
   */
  #setDefaultSelection() {
    try {
      if (!this.inputTarget.value) return;

      const query = this.inputTarget.value.toLowerCase();
      let matched = false;

      // Try to find matching item
      for (const item of this.itemTargets) {
        const value = (
          item.dataset["viral-Select2ValueParam"] || ""
        ).toLowerCase();
        const primary = (
          item.dataset["viral-Select2PrimaryParam"] || ""
        ).toLowerCase();

        // Match by value or primary text
        if (value === query || primary === query) {
          this.#isItemSelected = true;
          this.#updateSelection(
            item.dataset["viral-Select2PrimaryParam"],
            item.dataset["viral-Select2ValueParam"],
          );
          matched = true;
          break;
        }
      }

      // If no match found but input has value, cache it
      if (!matched && this.inputTarget.value) {
        this.#cachedInputValue = this.inputTarget.value;
      }
    } catch (error) {
      console.error("❌ Error setting default selection:", error);
      this.#handleError(error, "setDefaultSelection");
    }
  }

  /**
   * 🖋️ Update input and hidden field values
   * Sets the display text and actual value
   *
   * @param {string} primary - The display text
   * @param {string} value - The actual value
   * @private
   */
  #updateSelection(primary, value) {
    try {
      if (!primary || !value) {
        throw new Error("Cannot update selection with empty values");
      }

      this.inputTarget.value = primary;
      this.#cachedInputValue = primary;
      this.hiddenTarget.value = value;
    } catch (error) {
      console.error("❌ Error updating selection:", error);
      this.#handleError(error, "updateSelection");
    }
  }

  /**
   * 🔄 Reset input to cached value
   * Restores input to last valid selection
   * @private
   */
  #resetInput() {
    try {
      if (this.#dropdown) this.#dropdown.hide();
      this.inputTarget.value = this.#cachedInputValue || "";
      this.inputTarget.focus();
      this.inputTarget.select();
    } catch (error) {
      console.error("❌ Error resetting input:", error);
    }
  }

  /**
   * 🔒 Handle dropdown focus out
   * Closes dropdown when focus leaves the component
   *
   * @param {FocusEvent} event - The focus event
   * @private
   */
  #handleDropdownFocusOut(event) {
    try {
      // Only hide if focus moved outside the dropdown
      if (!this.dropdownTarget.contains(event.relatedTarget)) {
        if (this.#dropdown) this.#dropdown.hide();
      }
    } catch (error) {
      console.error("❌ Error handling focus out:", error);
    }
  }

  /**
   * ✅ Validate required targets
   * Ensures all required DOM elements are present
   * @private
   */
  #validateTargets() {
    const missingTargets = [];

    // Check for required targets
    if (!this.hasInputTarget) missingTargets.push("input");
    if (!this.hasHiddenTarget) missingTargets.push("hidden");
    if (!this.hasDropdownTarget) missingTargets.push("dropdown");
    if (!this.hasScrollerTarget) missingTargets.push("scroller");

    // Throw error if any required targets are missing
    if (missingTargets.length > 0) {
      throw new Error(`Missing required targets: ${missingTargets.join(", ")}`);
    }
  }

  /**
   * ❌ Handle errors
   * Centralized error handling
   *
   * @param {Error} error - The error object
   * @param {string} source - Where the error occurred
   * @private
   */
  #handleError(error, source) {
    // Log error to console
    console.error(`❌ Select2Controller error in ${source}:`, error);
  }
}
