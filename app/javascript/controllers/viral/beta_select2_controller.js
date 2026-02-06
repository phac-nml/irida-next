import MenuController from "controllers/menu_controller";

/**
 * BetaSelect2Controller
 *
 * Accessible, searchable dropdown with keyboard navigation.
 * - Keyboard navigation (Arrow keys, Enter, Escape, Home, End)
 * - Search filtering
 * - ARIA roles and attributes for accessibility
 * - Dropdown positioning and focus management
 * - Submit button enable/disable logic
 */
export default class BetaSelect2Controller extends MenuController {
  static targets = [
    "trigger",
    "hidden",
    "menu",
    "scroller",
    "item",
    "empty",
    "submitButton",
  ];

  static outlets = ["spreadsheet-import"];

  #itemSelected = false;
  #cachedInputValue = "";
  #currentItemIndex = -1;
  #boundHandlers = {};

  static #KEY_CODES = {
    ARROW_DOWN: "ArrowDown",
    ARROW_UP: "ArrowUp",
    ENTER: "Enter",
    ESCAPE: "Escape",
    HOME: "Home",
    END: "End",
  };

  connect() {
    try {
      this.#validateTargets();
      this.#initializeDropdown();
      this.#setDefaultSelection();

      this.#boundHandlers.dropdownFocusOut =
        this.#handleDropdownFocusOut.bind(this);
      this.menuTarget.addEventListener(
        "focusout",
        this.#boundHandlers.dropdownFocusOut,
      );

      // Accessibility: set ARIA attributes
      this.triggerTarget.setAttribute("role", "combobox");
      this.triggerTarget.setAttribute("aria-autocomplete", "list");
      this.triggerTarget.setAttribute("aria-expanded", "false");
      this.triggerTarget.setAttribute(
        "aria-controls",
        this.scrollerTarget.id || "select2-listbox",
      );
      this.scrollerTarget.setAttribute("role", "listbox");
      this.scrollerTarget.id = this.scrollerTarget.id || "select2-listbox";
      this.itemTargets.forEach((item, idx) => {
        item.setAttribute("role", "option");
        item.setAttribute("id", `select2-option-${idx}`);
        item.setAttribute("aria-selected", "false");
      });

      this.element.setAttribute("data-controller-connected", "true");
    } catch (error) {
      this.#handleError(error, "connect");
    }
  }

  disconnect() {
    try {
      if (this.#boundHandlers.dropdownFocusOut) {
        this.menuTarget.removeEventListener(
          "focusout",
          this.#boundHandlers.dropdownFocusOut,
        );
      }
      super.hide();
    } catch (error) {
      this.#handleError(error, "disconnect");
    }
  }

  /**
   * Handles item selection triggered by click or keyboard (Enter key).
   * Determines the selected item, updates the input and hidden fields,
   * hides the dropdown, and sets focus back to the input.
   * @param {Event} event - The event object (e.g., click, keydown).
   */
  select(event) {
    try {
      let selectedItemData = null;

      // Case 1: Direct click on an item
      if (event.target?.dataset?.value && event.target?.dataset?.label) {
        selectedItemData = event.target.dataset;
        this.#setItemSelected(true); // Mark as selected only on direct interaction
      }
      // Case 2: Selection via keyboard navigation (Enter key)
      else if (this.#currentItemIndex >= 0) {
        const currentItem = this.#visibleItems()[this.#currentItemIndex];
        if (currentItem?.dataset?.value && currentItem?.dataset?.label) {
          selectedItemData = currentItem.dataset;
          // #setItemSelected is implicitly handled by #updateSelection if needed,
          // or might already be true from previous direct interaction.
          // Avoid setting it unconditionally here for keyboard nav.
        }
      }

      if (selectedItemData) {
        const { value, label } = selectedItemData;
        this.#updateSelection(value, label);
        super.hide();
        this.triggerTarget.focus();
      } else {
        // If no valid item was determined (edge case or unexpected state),
        // potentially reset or log, but avoid throwing an error unless critical.
        console.warn(
          "BetaSelect2Controller: Could not determine selected item.",
        );
        // Optionally, reset the input if no selection is confirmed
        // this.#resetInput();
      }
    } catch (error) {
      this.#handleError(error, "select");
    }
  }

  /**
   * Handles keyboard navigation for dropdown.
   * @param {KeyboardEvent} event
   */
  keydown(event) {
    try {
      if (!Object.values(BetaSelect2Controller.#KEY_CODES).includes(event.key))
        return;
      event.preventDefault();
      event.stopPropagation();

      switch (event.key) {
        case BetaSelect2Controller.#KEY_CODES.ARROW_DOWN:
          this.#navigateItems(1);
          break;
        case BetaSelect2Controller.#KEY_CODES.ARROW_UP:
          this.#navigateItems(-1);
          break;
        case BetaSelect2Controller.#KEY_CODES.HOME:
          this.#navigateToIndex(0);
          break;
        case BetaSelect2Controller.#KEY_CODES.END:
          this.#navigateToIndex(this.#visibleItems().length - 1);
          break;
        case BetaSelect2Controller.#KEY_CODES.ESCAPE:
          this.#resetInput();
          break;
        case BetaSelect2Controller.#KEY_CODES.ENTER:
          if (this.#currentItemIndex < 0) {
            super.show();
          } else {
            this.select(event);
          }
          break;
      }
    } catch (error) {
      this.#handleError(error, "keydown");
    }
  }

  showDropdown() {
    try {
      super.show();
    } catch (error) {
      this.#handleError(error, "showDropdown");
    }
  }

  hideDropdown() {
    try {
      super.hide();
    } catch (error) {
      this.#handleError(error, "hideDropdown");
    }
  }

  /**
   * Handles input filtering for dropdown items.
   */
  input() {
    try {
      const query = this.triggerTarget.value.toLowerCase().trim();
      let visibleItemCount = 0;

      this.#setItemSelected(false);

      this.itemTargets.forEach((item) => {
        const text = item.textContent.toLowerCase() || "";
        if (text.includes(query)) {
          item.classList.remove("hidden");
          visibleItemCount++;
        } else {
          item.classList.add("hidden");
        }
      });

      this.#currentItemIndex = -1;
      this.#updateAriaActiveDescendant();

      if (visibleItemCount > 0) {
        if (!super.isVisible()) {
          super.show();
        }
        this.emptyTarget.setAttribute("hidden", "");
        this.scrollerTarget.scrollTop = 0;
      } else {
        this.emptyTarget.removeAttribute("hidden");
      }
    } catch (error) {
      this.#handleError(error, "input");
    }
  }

  // --- Private helpers ---

  #setItemSelected(selected) {
    this.#itemSelected = selected;
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = !selected;
    }
  }

  #updateSelection(value, label) {
    if (!label || !value) {
      // It's better to handle this potential issue gracefully or log it,
      // rather than throwing an error that might break user flow.
      console.error(
        "BetaSelect2Controller: Attempted to update selection with invalid data.",
        { value, label },
      );
      return; // Prevent updating with invalid data
    }
    this.triggerTarget.value = label;
    this.triggerTarget.title = label;
    this.#cachedInputValue = value; // Cache the *value*, not the label
    this.hiddenTarget.value = value;
    this.#updateAriaSelected(label); // Update ARIA state based on the new selection

    // Ensure itemSelected state reflects a valid selection update
    this.#setItemSelected(true);

    if (this.hasSpreadsheetImportOutlet) {
      this.spreadsheetImportOutlet.checkFormInputsReadyForSubmit();
    }
    // Note: Hiding dropdown and focusing input are now handled back in the `select` method
    // after #updateSelection completes successfully.
  }

  #resetInput() {
    try {
      super.hide();
      if (this.#cachedInputValue) {
        this.hiddenTarget.value = this.#cachedInputValue;
        this.#setInputTargetValueFromCache();
        this.#setItemSelected(true);
      } else {
        this.triggerTarget.value = "";
        this.hiddenTarget.value = "";
        this.#setItemSelected(false);
      }
      this.triggerTarget.focus();
      this.#updateAriaActiveDescendant();

      if (this.hasSpreadsheetImportOutlet) {
        this.spreadsheetImportOutlet.checkFormInputsReadyForSubmit();
      }
    } catch (error) {
      this.#handleError(error, "resetInput");
    }
  }

  #navigateItems(direction) {
    const visibleItems = this.#visibleItems();
    if (visibleItems.length === 0) return;

    let newIndex = this.#currentItemIndex + direction;
    if (newIndex < 0) newIndex = 0;
    if (newIndex >= visibleItems.length) newIndex = visibleItems.length - 1;

    // Remove highlight from previous item
    if (this.#currentItemIndex >= 0 && visibleItems[this.#currentItemIndex]) {
      visibleItems[this.#currentItemIndex].classList.remove(
        "bg-slate-200",
        "border-slate-500",
      );
    }

    visibleItems[newIndex].focus();
    visibleItems[newIndex].classList.add("bg-slate-200", "border-slate-500"); // Optional: highlight focused item
    this.#currentItemIndex = newIndex;
    this.#ensureItemVisible(visibleItems[newIndex]);
    this.#updateAriaActiveDescendant();
  }

  #navigateToIndex(index) {
    const visibleItems = this.#visibleItems();
    if (visibleItems.length === 0) return;
    const newIndex = Math.max(0, Math.min(index, visibleItems.length - 1));

    // Remove highlight from previous item
    if (this.#currentItemIndex >= 0 && visibleItems[this.#currentItemIndex]) {
      visibleItems[this.#currentItemIndex].classList.remove(
        "bg-slate-200",
        "border-slate-500",
      );
    }

    visibleItems[newIndex].focus();
    visibleItems[newIndex].classList.add("bg-slate-200", "border-slate-500"); // Optional: highlight focused item
    this.#currentItemIndex = newIndex;
    this.#ensureItemVisible(visibleItems[newIndex]);
    this.#updateAriaActiveDescendant();
  }

  #visibleItems() {
    // Filter only items that are direct children of the scroller and not hidden
    // This assumes items are direct children or nested within a structure where
    // the parent visibility check is appropriate. Adjust if structure differs.
    return this.itemTargets.filter((item) => {
      // Check if the item itself or its immediate parent container is hidden
      const parentElement = item.closest("li") || item.parentNode; // Adjust selector if needed
      return (
        !item.classList.contains("hidden") &&
        !parentElement.classList.contains("hidden")
      );
    });
  }

  #ensureItemVisible(item) {
    if (!this.scrollerTarget || !item) return;
    item.scrollIntoView();
  }

  #initializeDropdown() {
    super.share({
      onHide: () => this.#onHide(),
    });
  }

  #onHide() {
    if (!this.#itemSelected) this.#setInputTargetValueFromCache();
  }

  #setDefaultSelection() {
    try {
      if (!this.triggerTarget.value) return;
      const query = this.triggerTarget.value;
      let matched = false;
      for (const item of this.itemTargets) {
        const { value, label } = item.dataset;
        if (value === query) {
          this.#itemSelected = true;
          this.#updateSelection(value, label);
          matched = true;
          break;
        }
      }
      if (!matched && this.triggerTarget.value) {
        throw new Error(
          "No matching item found for the trigger value. Please check your data.",
        );
      }
    } catch (error) {
      this.#handleError(error, "setDefaultSelection");
    }
  }

  #handleDropdownFocusOut(event) {
    try {
      if (!this.menuTarget.contains(event.relatedTarget)) {
        super.hide();
      }
    } catch (error) {
      this.#handleError(error, "handleDropdownFocusOut");
    }
  }

  #validateTargets() {
    const missingTargets = [];
    if (!this.hasTriggerTarget) missingTargets.push("trigger");
    if (!this.hasHiddenTarget) missingTargets.push("hidden");
    if (!this.hasMenuTarget) missingTargets.push("menu");
    if (!this.hasScrollerTarget) missingTargets.push("scroller");
    if (missingTargets.length > 0) {
      throw new Error(`Missing required targets: ${missingTargets.join(", ")}`);
    }
  }

  #handleError(error, source) {
    // In production, consider reporting errors to a logging service
    console.error(`BetaSelect2Controller error in ${source}:`, error);
  }

  #setInputTargetValueFromCache() {
    const inputValue = this.triggerTarget.value;
    if (inputValue === this.#cachedInputValue) return;
    const foundItem = this.itemTargets.find(
      (item) => item.dataset.value === this.#cachedInputValue,
    );
    if (foundItem === undefined || inputValue === "") {
      this.hiddenTarget.value = "";
      this.#cachedInputValue = "";
      this.#setItemSelected(false);
      if (this.hasSpreadsheetImportOutlet) {
        this.spreadsheetImportOutlet.checkFormInputsReadyForSubmit();
      }
      return;
    }
    this.triggerTarget.value = foundItem ? foundItem.dataset.label : "";
    this.#updateAriaSelected(this.triggerTarget.value);
  }

  #updateAriaSelected(selectedLabel) {
    this.itemTargets.forEach((item) => {
      item.setAttribute(
        "aria-selected",
        item.dataset.label === selectedLabel ? "true" : "false",
      );
    });
  }

  #updateAriaActiveDescendant() {
    const visibleItems = this.#visibleItems();
    const visibleItem = visibleItems[this.#currentItemIndex];
    if (this.#currentItemIndex >= 0 && visibleItem) {
      const activeId = visibleItem.id;
      this.triggerTarget.setAttribute("aria-activedescendant", activeId);
    } else {
      this.triggerTarget.removeAttribute("aria-activedescendant");
    }
  }
}
