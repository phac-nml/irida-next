import { Controller } from "@hotwired/stimulus";

/**
 * Select2Controller
 *
 * Accessible, searchable dropdown with keyboard navigation.
 * - Keyboard navigation (Arrow keys, Enter, Escape, Home, End)
 * - Search filtering
 * - ARIA roles and attributes for accessibility
 * - Dropdown positioning and focus management
 * - Submit button enable/disable logic
 */
export default class Select2Controller extends Controller {
  static targets = [
    "input",
    "hidden",
    "dropdown",
    "scroller",
    "item",
    "empty",
    "submitButton",
  ];

  #itemSelected = false;
  #cachedInputValue = "";
  #currentItemIndex = -1;
  #dropdown = null;
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
      this.dropdownTarget.addEventListener(
        "focusout",
        this.#boundHandlers.dropdownFocusOut,
      );

      // Accessibility: set ARIA attributes
      this.inputTarget.setAttribute("role", "combobox");
      this.inputTarget.setAttribute("aria-autocomplete", "list");
      this.inputTarget.setAttribute("aria-expanded", "false");
      this.inputTarget.setAttribute(
        "aria-controls",
        this.scrollerTarget.id || "select2-listbox",
      );
      this.scrollerTarget.setAttribute("role", "listbox");
      this.scrollerTarget.id = this.scrollerTarget.id || "select2-listbox";
      this.itemTargets.forEach((item, idx) => {
        item.setAttribute("role", "option");
        item.setAttribute("id", `select2-option-${idx}`);
        item.setAttribute("aria-selected", "false");
        item.setAttribute("tabindex", "-1"); // Make items programmatically focusable
      });

      this.element.setAttribute("data-controller-connected", "true");
    } catch (error) {
      this.#handleError(error, "connect");
    }
  }

  disconnect() {
    try {
      if (this.#boundHandlers.dropdownFocusOut) {
        this.dropdownTarget.removeEventListener(
          "focusout",
          this.#boundHandlers.dropdownFocusOut,
        );
      }
      if (this.#dropdown) {
        this.#dropdown.hide();
        this.#dropdown = null;
      }
    } catch (error) {
      this.#handleError(error, "disconnect");
    }
  }

  /**
   * Handles item selection (click or keyboard).
   * @param {Event} event
   */
  select(event) {
    try {
      const { label, value } = event.target.dataset;
      if (!label || !value)
        throw new Error("Invalid selection: missing label or value.");
      this.#updateSelection(value, label);
      this.#setItemSelected(true);
      if (this.#dropdown) this.#dropdown.hide();
      this.inputTarget.focus();
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
      if (!Object.values(Select2Controller.#KEY_CODES).includes(event.key))
        return;
      event.preventDefault();
      event.stopPropagation();

      switch (event.key) {
        case Select2Controller.#KEY_CODES.ARROW_DOWN:
          this.#navigateItems(1);
          break;
        case Select2Controller.#KEY_CODES.ARROW_UP:
          this.#navigateItems(-1);
          break;
        case Select2Controller.#KEY_CODES.HOME:
          this.#navigateToIndex(0);
          break;
        case Select2Controller.#KEY_CODES.END:
          this.#navigateToIndex(this.#visibleItems().length - 1);
          break;
        case Select2Controller.#KEY_CODES.ESCAPE:
          this.#resetInput();
          break;
        case Select2Controller.#KEY_CODES.ENTER:
          if (event.target.nodeName === "INPUT") {
            if (this.#dropdown) this.#dropdown.show();
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
      if (this.#dropdown) this.#dropdown.show();
      this.inputTarget.setAttribute("aria-expanded", "true");
    } catch (error) {
      this.#handleError(error, "showDropdown");
    }
  }

  hideDropdown() {
    try {
      if (this.#dropdown) this.#dropdown.hide();
      this.inputTarget.setAttribute("aria-expanded", "false");
    } catch (error) {
      this.#handleError(error, "hideDropdown");
    }
  }

  /**
   * Handles input filtering for dropdown items.
   */
  input(event) {
    try {
      const query = this.inputTarget.value.toLowerCase().trim();
      let visibleItemCount = 0;

      this.#setItemSelected(false);

      this.itemTargets.forEach((item) => {
        const text = item.textContent.toLowerCase() || "";
        if (text.includes(query)) {
          item.parentNode.classList.remove("hidden");
          visibleItemCount++;
        } else {
          item.parentNode.classList.add("hidden");
        }
      });

      this.#currentItemIndex = -1;
      this.#updateAriaActiveDescendant();

      if (visibleItemCount > 0) {
        if (this.#dropdown) this.#dropdown.show();
        this.emptyTarget.classList.add("hidden");
        this.scrollerTarget.scrollTop = 0;
      } else {
        this.emptyTarget.classList.remove("hidden");
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
    if (!label || !value)
      throw new Error("Cannot update selection with empty values");
    this.inputTarget.value = label;
    this.#cachedInputValue = value;
    this.hiddenTarget.value = value;
    this.hideDropdown();
    this.inputTarget.focus();
    this.#updateAriaSelected(label);
  }

  #resetInput() {
    try {
      if (this.#dropdown) this.#dropdown.hide();
      if (this.#cachedInputValue) {
        this.hiddenTarget.value = this.#cachedInputValue;
        this.#setInputTargetValueFromCache();
        this.#setItemSelected(true);
      } else {
        this.inputTarget.value = "";
        this.hiddenTarget.value = "";
        this.#setItemSelected(false);
      }
      this.inputTarget.focus();
      this.#updateAriaActiveDescendant();
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
      visibleItems[this.#currentItemIndex].classList.remove("bg-slate-100");
    }

    visibleItems[newIndex].focus();
    visibleItems[newIndex].classList.add("bg-slate-100"); // Optional: highlight focused item
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
      visibleItems[this.#currentItemIndex].classList.remove("bg-slate-100");
    }

    visibleItems[newIndex].focus();
    visibleItems[newIndex].classList.add("bg-slate-100"); // Optional: highlight focused item
    this.#currentItemIndex = newIndex;
    this.#ensureItemVisible(visibleItems[newIndex]);
    this.#updateAriaActiveDescendant();
  }

  #visibleItems() {
    return this.itemTargets.filter(
      (item) => !item.parentNode.classList.contains("hidden"),
    );
  }

  #ensureItemVisible(item) {
    if (!this.scrollerTarget || !item) return;
    const container = this.scrollerTarget;
    const containerRect = container.getBoundingClientRect();
    const itemRect = item.getBoundingClientRect();
    if (itemRect.bottom > containerRect.bottom) {
      container.scrollTop += itemRect.bottom - containerRect.bottom;
    } else if (itemRect.top < containerRect.top) {
      container.scrollTop -= containerRect.top - itemRect.top;
    }
  }

  #initializeDropdown() {
    try {
      if (typeof Dropdown !== "function") {
        throw new Error(
          "Flowbite Dropdown class not found. Make sure Flowbite JS is loaded.",
        );
      }
      this.#dropdown = new Dropdown(this.dropdownTarget, this.inputTarget, {
        placement: "bottom",
        triggerType: "click",
        offsetSkidding: 0,
        offsetDistance: 10,
        delay: 300,
        onShow: () => {
          this.dropdownTarget.style.width = `${this.inputTarget.offsetWidth}px`;
          this.inputTarget.setAttribute("aria-expanded", "true");
        },
        onHide: () => {
          this.inputTarget.setAttribute("aria-expanded", "false");
          if (!this.#itemSelected) this.#setInputTargetValueFromCache();
        },
      });
    } catch (error) {
      this.#handleError(error, "initializeDropdown");
    }
  }

  #setDefaultSelection() {
    try {
      if (!this.inputTarget.value) return;
      const query = this.inputTarget.value;
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
      if (!matched && this.inputTarget.value) {
        throw new Error(
          "No matching item found for the input value. Please check your data.",
        );
      }
    } catch (error) {
      this.#handleError(error, "setDefaultSelection");
    }
  }

  #handleDropdownFocusOut(event) {
    try {
      if (!this.dropdownTarget.contains(event.relatedTarget)) {
        if (this.#dropdown) this.#dropdown.hide();
      }
    } catch (error) {
      this.#handleError(error, "handleDropdownFocusOut");
    }
  }

  #validateTargets() {
    const missingTargets = [];
    if (!this.hasInputTarget) missingTargets.push("input");
    if (!this.hasHiddenTarget) missingTargets.push("hidden");
    if (!this.hasDropdownTarget) missingTargets.push("dropdown");
    if (!this.hasScrollerTarget) missingTargets.push("scroller");
    if (missingTargets.length > 0) {
      throw new Error(`Missing required targets: ${missingTargets.join(", ")}`);
    }
  }

  #handleError(error, source) {
    // In production, consider reporting errors to a logging service
    console.error(`Select2Controller error in ${source}:`, error);
  }

  #setInputTargetValueFromCache() {
    const foundItem = this.itemTargets.find(
      (item) => item.dataset.value === this.#cachedInputValue,
    );
    this.inputTarget.value = foundItem ? foundItem.dataset.label : "";
    this.#updateAriaSelected(this.inputTarget.value);
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
    if (this.#currentItemIndex >= 0 && visibleItems[this.#currentItemIndex]) {
      const activeId = visibleItems[this.#currentItemIndex].id;
      this.inputTarget.setAttribute("aria-activedescendant", activeId);
    } else {
      this.inputTarget.removeAttribute("aria-activedescendant");
    }
  }
}
