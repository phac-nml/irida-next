import { Controller } from "@hotwired/stimulus";
import debounce from "debounce";
import { announce } from "utilities/live_region";
import {
  isPrintableCharacter,
  getLowercaseContent,
  highlightOption,
  setActiveDescendant,
} from "controllers/combobox/utils";
import FloatingDropdown from "utilities/floating_dropdown";

/**
 * Accessible, searchable dropdown with keyboard navigation.
 * - Keyboard navigation (Arrow keys, Enter, Escape, Home, End)
 * - Search filtering
 * - ARIA roles and attributes for accessibility
 * - Dropdown positioning and focus management
 */
export default class extends Controller {
  static targets = [
    "combobox",
    "listbox",
    "hidden",
    "ariaLiveUpdate",
    "indicatorButton",
    "indicatorClearButton",
  ];
  static values = {
    clearSelectionLabel: String,
    noResultsText: String,
    showOptionsLabel: String,
    singleResultText: String,
    multipleResultsText: String,
  };

  #floatingDropdown = null;
  #filter;
  #filteredOptions;
  #allOptions;
  #option;
  #firstOption;
  #lastOption;

  connect() {
    this.#filter = this.comboboxTarget.value;
    this.#filteredOptions = [];
    this.#allOptions = [];
    this.#option = null;
    this.#firstOption = null;
    this.#lastOption = null;

    this.boundOnBackgroundMouseDown = this.#onBackgroundMouseDown.bind(this);
    this.boundOnComboboxKeyDown = this.#onComboboxKeyDown.bind(this);
    this.boundOnComboboxKeyUp = this.#onComboboxKeyUp.bind(this);
    this.boundOnComboboxClick = this.#onComboboxClick.bind(this);
    this.boundOnOptionClick = this.#onOptionClick.bind(this);
    this.boundOnComboboxFocus = this.#onComboboxFocus.bind(this);

    this.#floatingDropdown = new FloatingDropdown({
      trigger: this.comboboxTarget,
      dropdown: this.listboxTarget,
      manageAria: false,
      onShow: () => this.#onShow(),
      onHide: () => this.#onHide(),
    });

    // Add debounced filter for search input
    this.debouncedFilterAndUpdate = debounce(() => {
      const option = this.#filterOptions();
      this.#setOption(option);
      if (
        !this.#floatingDropdown.isVisible() &&
        this.comboboxTarget.value.length
      ) {
        this.#floatingDropdown.show();
      }
    }, 300);

    // Add event handlers
    document.body.addEventListener(
      "mousedown",
      this.boundOnBackgroundMouseDown,
      true,
    );

    this.#addComboboxEventListeners(this.comboboxTarget);
    this.#addListboxEventListeners(this.listboxTarget);

    // Initialize
    if (this.#filter) {
      const option = this.#filterOptions();
      this.#setOption(option);
      this.#setValue(option);
    }

    this.#updateIndicatorState();
  }

  disconnect() {
    this.debouncedFilterAndUpdate.clear();

    // Remove event handlers
    document.body.removeEventListener(
      "mousedown",
      this.boundOnBackgroundMouseDown,
      true,
    );

    this.#removeComboboxEventListeners(this.comboboxTarget);
    this.#removeListboxEventListeners(this.listboxTarget);

    this.#floatingDropdown?.destroy();
    this.#floatingDropdown = null;
  }

  #addListboxEventListeners(container) {
    container
      .querySelectorAll(':scope > [role="option"], [role="group"]')
      .forEach((item) => {
        this.#allOptions.push(item);
        this.#addListboxOptionEventListeners(item);
      });
  }

  #removeListboxEventListeners(container) {
    container
      .querySelectorAll(':scope > [role="option"], [role="group"]')
      .forEach((item) => {
        this.#removeListboxOptionEventListeners(item);
      });
  }

  #renderNoResults() {
    const noResultsOption = document.createElement("div");
    noResultsOption.setAttribute("role", "option");
    noResultsOption.setAttribute("aria-disabled", "true");
    noResultsOption.setAttribute("aria-selected", "false");
    noResultsOption.className =
      "px-3 py-2 text-sm text-slate-500 dark:text-slate-300";
    const noResultsMessage =
      this.hasNoResultsTextValue && this.noResultsTextValue
        ? this.noResultsTextValue
        : "No results found";
    noResultsOption.textContent = noResultsMessage;
    this.listboxTarget.appendChild(noResultsOption);
  }

  #announceNumberOfResults() {
    if (this.hasAriaLiveUpdateTarget) {
      const numItems = this.#filteredOptions.length;
      let message;
      if (numItems === 0) {
        message = this.noResultsTextValue;
      } else if (numItems === 1) {
        message = this.singleResultTextValue;
      } else {
        message = this.multipleResultsTextValue.replace(
          "%{num}",
          String(numItems),
        );
      }
      if (message) {
        announce(message, { element: this.ariaLiveUpdateTarget });
      }
    }
  }

  // ComboboxAutocomplete events

  #filterOptions() {
    this.#filter = this.comboboxTarget.value;
    const filter = this.#filter.toLowerCase();
    this.#filteredOptions = [];
    this.listboxTarget.innerHTML = "";

    this.#allOptions.forEach((allOption) => {
      let flag = false;
      const category = allOption.cloneNode(true);
      this.#addListboxOptionEventListeners(category);

      if (category.role === "group") {
        const categoryOptions = category.querySelectorAll('[role="option"]');
        categoryOptions.forEach((categoryOption) => {
          if (
            filter.length === 0 ||
            getLowercaseContent(categoryOption).indexOf(filter) >= 0
          ) {
            flag = true;
            this.#filteredOptions.push(
              highlightOption(categoryOption, this.#filter),
            );
          } else {
            category.removeChild(categoryOption);
          }
        });
      } else {
        if (
          filter.length === 0 ||
          getLowercaseContent(category).indexOf(filter) >= 0
        ) {
          flag = true;
          this.#filteredOptions.push(highlightOption(category, this.#filter));
        }
      }

      if (flag) {
        this.listboxTarget.appendChild(category);
      }
    });

    const option = this.#populateCurrentFirstLastOptions();
    if (option === null) {
      this.#renderNoResults();
    }
    if (this.#floatingDropdown.isVisible()) {
      this.#announceNumberOfResults();
    }

    return option;
  }

  #populateCurrentFirstLastOptions() {
    const currentOption = this.#option;
    const numItems = this.#filteredOptions.length;
    let option;

    if (numItems > 0) {
      this.#firstOption = this.#filteredOptions[0];
      this.#lastOption = this.#filteredOptions[numItems - 1];

      if (currentOption && this.#filteredOptions.indexOf(currentOption) >= 0) {
        option = currentOption;
      } else {
        option = this.#firstOption;
      }
    } else {
      this.#firstOption = null;
      option = null;
      this.#lastOption = null;
    }
    return option;
  }

  #setValue(option) {
    this.hiddenTarget.value = option ? option.getAttribute("data-value") : "";
    this.#filter = option ? option.textContent : "";
    this.comboboxTarget.value = this.#filter;
    this.comboboxTarget.setSelectionRange(
      this.#filter.length,
      this.#filter.length,
    );
    this.hiddenTarget.dispatchEvent(new Event("change", { bubbles: true }));
    this.comboboxTarget.dispatchEvent(new Event("change", { bubbles: true }));
    this.#updateIndicatorState();
  }

  #setOption(option) {
    this.#option = option;
    setActiveDescendant(option, this.comboboxTarget);
    this.#filteredOptions.forEach((opt) => {
      if (opt === option) {
        opt.setAttribute("aria-selected", "true");
        option.scrollIntoView({ behavior: "smooth", block: "nearest" });
        this.#onOptionFocus();
      } else {
        opt.removeAttribute("aria-selected");
      }
    });
  }

  #getPreviousOption(currentOption) {
    if (currentOption !== this.#firstOption) {
      const index = this.#filteredOptions.indexOf(currentOption);
      return this.#filteredOptions[index - 1];
    }
    return this.#lastOption;
  }

  #getNextOption(currentOption) {
    if (currentOption !== this.#lastOption) {
      const index = this.#filteredOptions.indexOf(currentOption);
      return this.#filteredOptions[index + 1];
    }
    return this.#firstOption;
  }

  // Menu display methods

  #hasOptions() {
    return this.#filteredOptions.length;
  }

  #hasSelection() {
    return this.hiddenTarget.value.length > 0;
  }

  #updateIndicatorState() {
    if (this.hasIndicatorButtonTarget) {
      this.indicatorButtonTarget.setAttribute(
        "aria-label",
        this.showOptionsLabelValue,
      );
      this.indicatorButtonTarget.setAttribute("title", this.showOptionsLabelValue);
    }

    if (!this.hasIndicatorClearButtonTarget) return;

    const hasSelection = this.#hasSelection();
    this.indicatorClearButtonTarget.classList.toggle("hidden", !hasSelection);
    this.indicatorClearButtonTarget.classList.toggle("flex", hasSelection);
    this.indicatorClearButtonTarget.setAttribute(
      "aria-label",
      this.clearSelectionLabelValue,
    );
    this.indicatorClearButtonTarget.setAttribute(
      "title",
      this.clearSelectionLabelValue,
    );
  }

  #clearSelection() {
    this.#setValue();
    this.#setOption(null);
    this.#filterOptions();
    this.#floatingDropdown.hide();
    this.comboboxTarget.focus();
  }

  #onShow() {
    this.listboxTarget.style.display = "block";
    this.listboxTarget.removeAttribute("aria-hidden");
    this.comboboxTarget.setAttribute("aria-expanded", "true");
  }

  #onHide() {
    this.listboxTarget.style.display = "none";
    this.listboxTarget.setAttribute("aria-hidden", "true");
    this.comboboxTarget.setAttribute("aria-expanded", "false");
  }

  // Combobox events

  #onComboboxKeyDown(event) {
    let flag = false;
    const altKey = event.altKey;

    if (event.ctrlKey || event.shiftKey) {
      return;
    }

    switch (event.key) {
      case "Enter": {
        this.debouncedFilterAndUpdate.flush();
        this.#setValue(this.#option);
        this.#floatingDropdown.hide();
        flag = true;
        break;
      }
      case "Down":
      case "ArrowDown":
        if (this.#filteredOptions.length > 0) {
          if (altKey) {
            this.#setOption(null);
          } else {
            if (this.#filteredOptions.length > 1) {
              this.#setOption(this.#getNextOption(this.#option));
            } else {
              this.#setOption(this.#firstOption);
            }
          }
          if (!this.#floatingDropdown.isVisible()) {
            this.#floatingDropdown.show();
          }
        }
        flag = true;
        break;

      case "Up":
      case "ArrowUp":
        if (this.#hasOptions()) {
          if (this.#floatingDropdown.isVisible()) {
            this.#setOption(this.#getPreviousOption(this.#option));
          } else {
            this.#floatingDropdown.show();
            if (!altKey) {
              this.#setOption(this.#lastOption);
            }
          }
        }
        flag = true;
        break;

      case "Esc":
      case "Escape":
        if (this.#floatingDropdown.isVisible()) {
          this.#floatingDropdown.hide();
        } else {
          this.#setValue();
          this.#setOption(null);
        }
        flag = true;
        break;

      case "Tab": {
        this.debouncedFilterAndUpdate.flush();
        this.#setValue(this.#option);
        this.#floatingDropdown.hide();
        break;
      }
      case "Home": {
        this.comboboxTarget.setSelectionRange(0, 0);
        flag = true;
        break;
      }
      case "End": {
        const length = this.comboboxTarget.value.length;
        this.comboboxTarget.setSelectionRange(length, length);
        flag = true;
        break;
      }
      default: {
        break;
      }
    }

    if (flag) {
      event.stopPropagation();
      event.preventDefault();
    }
  }

  #onComboboxKeyUp(event) {
    let flag = false;
    const char = event.key;

    if (isPrintableCharacter(char)) {
      this.#filter += char;
    }

    if (event.key === "Escape" || event.key === "Esc") {
      return;
    }

    switch (event.key) {
      case "Backspace":
        this.debouncedFilterAndUpdate();
        flag = true;
        break;

      case "Left":
      case "ArrowLeft":
      case "Right":
      case "ArrowRight":
      case "Home":
      case "End":
        this.#setOption(null);
        flag = true;
        break;

      default:
        if (isPrintableCharacter(char)) {
          this.debouncedFilterAndUpdate();
          flag = true;
        }

        break;
    }

    if (flag) {
      event.stopPropagation();
      event.preventDefault();
    }
  }

  #onComboboxClick() {
    this.#floatingDropdown.toggle();
  }

  #onComboboxFocus() {
    this.#filterOptions();
  }

  #onBackgroundMouseDown(event) {
    if (
      !this.comboboxTarget.contains(event.target) &&
      !this.listboxTarget.contains(event.target) &&
      !this.indicatorButtonTarget.contains(event.target) &&
      (!this.hasIndicatorClearButtonTarget ||
        !this.indicatorClearButtonTarget.contains(event.target))
    ) {
      this.debouncedFilterAndUpdate.flush();
      this.#setValue(this.#option);
      this.#floatingDropdown.hide();
    }
  }

  onIndicatorMouseDown(event) {
    event.preventDefault();
  }

  onIndicatorClick(event) {
    event.preventDefault();
    event.stopPropagation();

    this.comboboxTarget.focus();
    this.#floatingDropdown.toggle();
  }

  onClearClick(event) {
    event.preventDefault();
    event.stopPropagation();

    this.#clearSelection();
  }

  // Listbox Option events

  #onOptionClick(event) {
    const option = event.target.closest('[role="option"]');
    if (option) {
      this.#setValue(option);
      this.#setOption(option);
      this.#floatingDropdown.hide();
      this.comboboxTarget.focus();
    }
  }

  #onOptionFocus() {
    const dialog = this.#option.closest("dialog");
    if (dialog) {
      const rect = this.#option.getBoundingClientRect();
      if (rect.top < 0 || rect.top + rect.height > dialog.offsetHeight) {
        const dialogContents = dialog.querySelector(".dialog--section");
        dialogContents.scrollBy(0, rect.top);
      }
    }
  }

  // Event handlers

  #addComboboxEventListeners(combobox) {
    combobox.addEventListener("keydown", this.boundOnComboboxKeyDown);
    combobox.addEventListener("keyup", this.boundOnComboboxKeyUp);
    combobox.addEventListener("click", this.boundOnComboboxClick);
    combobox.addEventListener("focus", this.boundOnComboboxFocus);
  }

  #removeComboboxEventListeners(combobox) {
    combobox.removeEventListener("keydown", this.boundOnComboboxKeyDown);
    combobox.removeEventListener("keyup", this.boundOnComboboxKeyUp);
    combobox.removeEventListener("click", this.boundOnComboboxClick);
    combobox.removeEventListener("focus", this.boundOnComboboxFocus);
  }

  #addListboxOptionEventListeners(option) {
    option.addEventListener("click", this.boundOnOptionClick);
  }

  #removeListboxOptionEventListeners(option) {
    option.removeEventListener("click", this.boundOnOptionClick);
  }
}
