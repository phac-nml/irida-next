import { Controller } from "@hotwired/stimulus";

/**
 * 🌟 Select2Controller 🌟
 *
 * A custom dropdown selector with keyboard navigation and search functionality.
 * This controller implements a lightweight alternative to the Select2 library,
 * adhering to ARIA combobox pattern with listbox popup.
 *
 * 📚 References:
 * - https://www.w3.org/WAI/ARIA/apg/patterns/combobox/examples/combobox-listbox/
 *
 * 📋 Features:
 * - Keyboard navigation (up/down/enter/escape)
 * - Search filtering
 * - Accessible focus management (aria-activedescendant, aria-selected)
 * - Dropdown positioning
 */
export default class Select2Controller extends Controller {
  /**
   * 🎯 Stimulus Targets
   * Define all DOM elements that this controller needs to interact with
   */
  static targets = [
    "input", // 📝 Text input for searching/displaying selected value (role="combobox")
    "hidden", // 🙈 Hidden input that stores the actual value
    "dropdown", // 📦 Dropdown container (visual wrapper)
    "scroller", // 📜 Scrollable container for items (role="listbox")
    "item", // 🔘 Individual selectable items (buttons inside li[role="option"])
    "empty", // 🕸️ Empty state message when no results found
    "submitButton", // 🖱️ Submit button for form submission
  ];

  /**
   * 🔒 Private Properties
   * Using private class fields for better encapsulation
   */
  #isItemSelected = false; // 🚩 Flag to track if an item has been selected
  #cachedInputValue = ""; // 💾 Stores the last valid input value
  #currentItemIndex = -1; // 🔍 Tracks current position during keyboard navigation
  #dropdown = null; // 📦 Reference to the Flowbite dropdown instance (used for show/hide)
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
    HOME: "Home",
    END: "End",
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

      // Initialize dropdown (just for show/hide, not full Flowbite Dropdown)
      // We manage the core logic here
      this.#initializeDropdownVisuals();
      this.#setDefaultSelection();

      // Set up event handlers with proper binding
      this.#boundHandlers.dropdownFocusOut =
        this.#handleDropdownFocusOut.bind(this);
      this.element.addEventListener("focusout", this.#boundHandlers.dropdownFocusOut);

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
        this.element.removeEventListener(
          "focusout",
          this.#boundHandlers.dropdownFocusOut,
        );
      }

      // Hide dropdown if open
      this.hide();

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
   * 🖱️ Handle item selection (click)
   * Called when an item is clicked
   *
   * @param {Event} event - The triggering click event
   */
  select(event) {
    try {
      const selectedItem = event.currentTarget; // The button element
      const primary = selectedItem.dataset.viralSelect2PrimaryParam;
      const value = selectedItem.dataset.viralSelect2ValueParam;

      // Validate selection data
      if (!primary || !value) {
        throw new Error("Invalid selection: missing primary or value data");
      }

      // Update selection and UI state
      this.#updateSelection(primary, value);
      this.#isItemSelected = true;
      if (this.hasSubmitButtonTarget) {
        this.submitButtonTarget.disabled = false;
      }

      // Update ARIA state for all items
      this.#updateAriaSelected(selectedItem);

      // Hide dropdown and focus input
      this.hide();
      this.inputTarget.focus();
    } catch (error) {
      console.error("❌ Error in select action:", error);
      this.#handleError(error, "select");
    }
  }

  /**
   * ⌨️ Handle keyboard interaction on the input
   * Manages arrow keys, enter, escape, home, end for dropdown navigation
   *
   * @param {KeyboardEvent} event - The keyboard event
   */
  keydown(event) {
    try {
      const isDropdownVisible = !this.dropdownTarget.classList.contains("hidden");

      // Only process specific keys
      if (!Object.values(Select2Controller.#KEY_CODES).includes(event.key)) {
        return;
      }

      // Handle keys differently based on dropdown visibility
      if (isDropdownVisible) {
        event.preventDefault(); // Prevent default browser actions for navigation keys
        event.stopPropagation();

        switch (event.key) {
          case Select2Controller.#KEY_CODES.ARROW_DOWN:
            this.#navigateItems(1);
            break;
          case Select2Controller.#KEY_CODES.ARROW_UP:
            this.#navigateItems(-1);
            break;
          case Select2Controller.#KEY_CODES.HOME:
            this.#navigateItems(0, true); // Go to first item
            break;
          case Select2Controller.#KEY_CODES.END:
            this.#navigateItems(-1, true); // Go to last item
            break;
          case Select2Controller.#KEY_CODES.ENTER:
            this.#selectCurrentItem();
            break;
          case Select2Controller.#KEY_CODES.ESCAPE:
            this.hide();
            this.#resetInput();
            break;
        }
      } else {
        // Dropdown is hidden
        if (
          event.key === Select2Controller.#KEY_CODES.ARROW_DOWN ||
          event.key === Select2Controller.#KEY_CODES.ARROW_UP ||
          event.key === Select2Controller.#KEY_CODES.ENTER
        ) {
          event.preventDefault();
          event.stopPropagation();
          this.show(); // Show dropdown on arrow down/up or enter if hidden
        }
      }
    } catch (error) {
      console.error("❌ Error in keydown action:", error);
      this.#handleError(error, "keydown");
    }
  }

  /**
   * ⌨️ Handle input event on the text field
   * Filters items based on query and shows/hides dropdown
   */
  input() {
    try {
      const query = this.inputTarget.value;

      // Reset selection state if input changes
      if (this.#isItemSelected && query !== this.#cachedInputValue) {
        this.#resetSelectionState();
      }

      // Filter items and show dropdown
      this.#filterItems(query);
      if (this.#getVisibleItems().length > 0) {
        this.show();
        this.#resetActiveDescendant(); // Clear active descendant when typing
      } else {
        this.hide(); // Hide if no results
      }
    } catch (error) {
      console.error("❌ Error in input filtering:", error);
      this.#handleError(error, "input");
    }
  }

  /**
   * 👀 Show the dropdown
   */
  show() {
    if (this.dropdownTarget.classList.contains("hidden")) {
      this.dropdownTarget.classList.remove("hidden");
      this.inputTarget.setAttribute("aria-expanded", "true");
      this.#filterItems(this.inputTarget.value); // Re-filter on show
      this.#resetNavigation(); // Reset navigation index when showing
      this.#focusInput(); // Ensure input stays focused
      console.debug("🔽 Dropdown shown");
    }
  }

  /**
   * 🙈 Hide the dropdown
   */
  hide() {
    if (!this.dropdownTarget.classList.contains("hidden")) {
      this.dropdownTarget.classList.add("hidden");
      this.inputTarget.setAttribute("aria-expanded", "false");
      this.#resetActiveDescendant();
      this.#resetAriaSelected();
      console.debug("🔼 Dropdown hidden");
    }
  }

  /**
   * 🤔 Hide dropdown only if focus moves outside the component
   * @param {FocusEvent} event
   */
  hideIfNeeded(event) {
    // Use setTimeout to allow focus to move to a related target first
    setTimeout(() => {
      if (!this.element.contains(document.activeElement)) {
        this.hide();
        if (!this.#isItemSelected) {
          this.#resetInput(); // Reset input if nothing was selected
        }
      }
    }, 0);
  }

  /**
   * 🛠️ Private Helper Methods
   * Internal logic for the controller
   */

  /**
   * ✅ Validate that required Stimulus targets are present
   * @throws {Error} If a required target is missing
   */
  #validateTargets() {
    const requiredTargets = ["input", "hidden", "dropdown", "scroller"];
    requiredTargets.forEach((target) => {
      if (!this.hasTarget(target)) {
        throw new Error(`Missing required target: ${target}`);
      }
    });
  }

  /**
   * 🎨 Initialize dropdown visuals (show/hide, positioning is via CSS)
   */
  #initializeDropdownVisuals() {
    // Basic setup, Flowbite Dropdown object isn't strictly needed
    // as we manage state manually for ARIA compliance.
    // Ensure initial state is hidden.
    this.dropdownTarget.classList.add("hidden");
    this.inputTarget.setAttribute("aria-expanded", "false");
    this.inputTarget.setAttribute("aria-autocomplete", "list"); // Indicate list completion
  }

  /**
   * 💾 Set initial selection based on hidden input's value
   */
  #setDefaultSelection() {
    const initialValue = this.hiddenTarget.value;
    if (initialValue) {
      const matchingItem = this.itemTargets.find(
        (item) => item.dataset.viralSelect2ValueParam === initialValue,
      );
      if (matchingItem) {
        const primary = matchingItem.dataset.viralSelect2PrimaryParam;
        this.#updateSelection(primary, initialValue, false); // Don't trigger change event on init
        this.#isItemSelected = true;
        this.#updateAriaSelected(matchingItem);
        if (this.hasSubmitButtonTarget) {
          this.submitButtonTarget.disabled = false;
        }
      } else {
        console.warn(
          `Initial value "${initialValue}" not found in options. Clearing input.`,
        );
        this.#resetSelectionState(); // Clear if value doesn't match any option
      }
    } else {
      this.#resetSelectionState(); // Ensure clean state if no initial value
    }
  }

  /**
   * 🔄 Update the selected value in inputs and cache
   * @param {string} primary - The primary text to display
   * @param {string} value - The actual value to store
   * @param {boolean} [triggerChangeEvent=true] - Whether to dispatch a change event
   */
  #updateSelection(primary, value, triggerChangeEvent = true) {
    this.inputTarget.value = primary;
    this.hiddenTarget.value = value;
    this.#cachedInputValue = primary;

    if (triggerChangeEvent) {
      // Dispatch events for potential external listeners
      this.hiddenTarget.dispatchEvent(new Event("change", { bubbles: true }));
      this.element.dispatchEvent(
        new CustomEvent("viral--select2:selection-changed", {
          bubbles: true,
          detail: { value, primary },
        }),
      );
      console.debug("✅ Selection updated:", { value, primary });
    }
  }

  /**
   * ⬅️ Reset input field to cached value or empty
   */
  #resetInput() {
    this.inputTarget.value = this.#isItemSelected ? this.#cachedInputValue : "";
    if (!this.#isItemSelected) {
      this.#resetSelectionState();
    }
    this.hide();
    this.#focusInput();
  }

  /**
   * 🧹 Reset the selection state (hidden value, item flag, button)
   */
  #resetSelectionState() {
    this.hiddenTarget.value = "";
    this.#isItemSelected = false;
    this.#cachedInputValue = "";
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = true;
    }
    this.#resetAriaSelected();
    this.#resetActiveDescendant();
    // Don't clear inputTarget.value here, handled by #resetInput or user typing
  }

  /**
   * 🖱️ Select the currently highlighted item (via keyboard)
   */
  #selectCurrentItem() {
    const visibleItems = this.#getVisibleItems();
    if (this.#currentItemIndex >= 0 && this.#currentItemIndex < visibleItems.length) {
      const selectedItem = visibleItems[this.#currentItemIndex];
      if (selectedItem) {
        // Simulate click event data for the select method
        this.select({ currentTarget: selectedItem });
      }
    }
  }

  /**
   * ⬇️⬆️ Navigate through visible items using keyboard
   * @param {number} direction - 1 for down, -1 for up
   * @param {boolean} [absolute=false] - If true, direction is treated as an index (0 for first, -1 for last)
   */
  #navigateItems(direction, absolute = false) {
    const visibleItems = this.#getVisibleItems();
    if (visibleItems.length === 0) return;

    let newIndex;
    if (absolute) {
      newIndex = direction === 0 ? 0 : visibleItems.length - 1;
    } else {
      newIndex = this.#currentItemIndex + direction;
    }

    // Clamp index within bounds
    newIndex = Math.max(0, Math.min(newIndex, visibleItems.length - 1));

    // Update state only if index changes
    if (newIndex !== this.#currentItemIndex) {
      this.#currentItemIndex = newIndex;
      this.#updateActiveDescendant(visibleItems[newIndex]);
      this.#scrollToItem(visibleItems[newIndex]);
      this.#updateAriaSelected(visibleItems[newIndex], true); // Update aria-selected for navigation
    }
  }

  /**
   * 🔍 Get all currently visible (not hidden by filtering) item buttons
   * @returns {Element[]}
   */
  #getVisibleItems() {
    return this.itemTargets.filter(
      (item) => !item.parentElement.classList.contains("hidden"),
    );
  }

  /**
   * 📜 Scroll the container to ensure the target item is visible
   * @param {Element} item - The item element (button) to scroll to
   */
  #scrollToItem(item) {
    if (!item) return;
    const itemTop = item.offsetTop;
    const itemBottom = itemTop + item.offsetHeight;
    const scrollerTop = this.scrollerTarget.scrollTop;
    const scrollerBottom = scrollerTop + this.scrollerTarget.clientHeight;

    if (itemTop < scrollerTop) {
      // Scroll up
      this.scrollerTarget.scrollTop = itemTop;
    } else if (itemBottom > scrollerBottom) {
      // Scroll down
      this.scrollerTarget.scrollTop = itemBottom - this.scrollerTarget.clientHeight;
    }
  }

  /**
   * 👇 Set the aria-activedescendant attribute on the input
   * @param {Element | null} item - The item element (button) to set as active, or null to clear
   */
  #updateActiveDescendant(item) {
    if (item && item.id) {
      this.inputTarget.setAttribute("aria-activedescendant", item.id);
    } else {
      this.#resetActiveDescendant();
    }
  }

  /**
   * ✨ Reset the aria-activedescendant attribute
   */
  #resetActiveDescendant() {
    this.inputTarget.removeAttribute("aria-activedescendant");
  }

  /**
   * ✅ Update aria-selected state for all items
   * @param {Element} selectedItem - The item that should be marked as selected
   * @param {boolean} [isNavigation=false] - True if called during keyboard navigation
   */
  #updateAriaSelected(selectedItem, isNavigation = false) {
    this.itemTargets.forEach((item) => {
      const isSelected = item === selectedItem;
      // Set aria-selected="true" only for the actually selected item (on click/enter)
      // or the currently navigated item. Set others to false.
      item.setAttribute("aria-selected", isSelected ? "true" : "false");

      // Optionally add visual indication for navigation focus (distinct from selection)
      // Example: item.classList.toggle("bg-primary-100", isSelected && isNavigation);
      // Example: item.classList.toggle("dark:bg-primary-800", isSelected && isNavigation);
    });
  }

  /**
   * ✨ Reset aria-selected for all items
   */
  #resetAriaSelected() {
    this.itemTargets.forEach((item) => {
      item.setAttribute("aria-selected", "false");
      // Optionally remove navigation focus class
      // item.classList.remove("bg-primary-100", "dark:bg-primary-800");
    });
  }

  /**
   * 🔄 Reset navigation index
   */
  #resetNavigation() {
    this.#currentItemIndex = -1;
  }

  /**
   * 👇 Focus the input element
   */
  #focusInput() {
    // Use requestAnimationFrame to ensure focus happens after potential DOM updates
    requestAnimationFrame(() => {
      this.inputTarget.focus();
    });
  }

  /**
   * 💧 Handle focusout event on the dropdown container
   * Used to hide the dropdown when focus moves outside
   *
   * @param {FocusEvent} event
   */
  #handleDropdownFocusOut(event) {
    // Check if the new focused element is still within the controller's element
    if (!this.element.contains(event.relatedTarget)) {
      this.hide();
      if (!this.#isItemSelected) {
        this.#resetInput(); // Reset if nothing was selected
      }
    }
  }

  /**
   * 🔍 Filter items based on input query
   * @param {string} query - The input query
   * @private
   */
  #filterItems(query) {
    const normalizedQuery = query.toLowerCase();
    let hasVisibleItems = false;

    this.itemTargets.forEach((item) => {
      const primaryText = item.dataset.viralSelect2PrimaryParam?.toLowerCase() || "";
      const secondaryText =
        item.dataset.viralSelect2SecondaryParam?.toLowerCase() || "";

      const isMatch =
        primaryText.includes(normalizedQuery) ||
        secondaryText.includes(normalizedQuery);

      item.parentElement.classList.toggle("hidden", !isMatch); // Hide the parent LI
      if (isMatch) {
        hasVisibleItems = true;
      }
    });

    // Toggle empty state visibility
    if (this.hasEmptyTarget) {
      this.emptyTarget.parentElement.classList.toggle("hidden", hasVisibleItems);
    }

    // Reset navigation index after filtering
    this.#resetNavigation();
    this.#resetActiveDescendant(); // Important: clear activedescendant during filtering

    // Show/hide dropdown based on results (handled in input() / show())
  }

  /**
   * 🆘 Handle errors gracefully
   * @param {Error} error - The error object
   * @param {string} source - The method where the error occurred
   */
  #handleError(error, source) {
    // Log error to console
    console.error(`❌ Select2Controller error in ${source}:`, error);
    // Potentially display a user-friendly message or disable the component
  }
}
