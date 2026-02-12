import MenuController from "controllers/menu_controller";
import debounce from "debounce";
import { announce } from "utilities/live_region";
import {
  isPrintableCharacter,
  getLowercaseContent,
  highlightOption,
  setActiveDescendant,
} from "controllers/combobox/utils";

/**
 * ComboboxController
 *
 * Accessible, searchable dropdown with keyboard navigation.
 * - Keyboard navigation (Arrow keys, Enter, Escape, Home, End)
 * - Search filtering
 * - ARIA roles and attributes for accessibility
 * - Dropdown positioning and focus management
 */
export default class ComboboxController extends MenuController {
  static targets = ["trigger", "menu", "hidden", "ariaLiveUpdate"];
  static values = {
    noResultsText: String,
    singleResultText: String,
    multipleResultsText: String,
  };

  #filter;
  #filteredOptions;
  #allOptions;
  #option;
  #firstOption;
  #lastOption;

  connect() {
    this.boundOnBackgroundMouseDown = this.#onBackgroundMouseDown.bind(this);
    this.boundOnTriggerKeyDown = this.#onTriggerKeyDown.bind(this);
    this.boundOnTriggerKeyUp = this.#onTriggerKeyUp.bind(this);
    this.boundOnOptionClick = this.#onOptionClick.bind(this);
    this.boundOnTriggerFocus = this.#onTriggerFocus.bind(this);

    this.#filter = "";
    this.#filteredOptions = [];
    this.#allOptions = [];
    this.#option = null;
    this.#firstOption = null;
    this.#lastOption = null;

    // Add debounced filter for search input
    this.debouncedFilterAndUpdate = debounce(() => {
      const option = this.#filterOptions();
      if (!super.isVisible() && this.triggerTarget.value.length) {
        super.show();
      }
      this.#setOption(option);
    }, 300);

    // Add event handlers
    document.body.addEventListener(
      "mousedown",
      this.boundOnBackgroundMouseDown,
      true,
    );

    this.#addTriggerEventListeners(this.triggerTarget);
    this.#addMenuEventListeners(this.menuTarget);

    // Initialize
    this.#setOption(this.#filterOptions());
  }

  disconnect() {
    this.debouncedFilterAndUpdate.clear();

    // Remove event handlers
    document.body.removeEventListener(
      "mousedown",
      this.boundOnBackgroundMouseDown,
      true,
    );

    this.#removeTriggerEventListeners(this.triggerTarget);
    this.#removeMenuEventListeners(this.menuTarget);

    super.disconnect();
  }

  #addMenuEventListeners(container) {
    container
      .querySelectorAll(':scope > [role="option"], [role="group"]')
      .forEach((item) => {
        this.#allOptions.push(item);
        this.#addMenuOptionEventListeners(item);
      });
  }

  #removeMenuEventListeners(container) {
    container
      .querySelectorAll(':scope > [role="option"], [role="group"]')
      .forEach((item) => {
        this.#removeMenuOptionEventListeners(item);
      });
  }

  #setValue(option) {
    this.hiddenTarget.value = option ? option.getAttribute("data-value") : "";
    this.#filter = option ? option.textContent : "";
    this.triggerTarget.value = this.#filter;
    this.triggerTarget.setSelectionRange(
      this.#filter.length,
      this.#filter.length,
    );
    this.#filterOptions();
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
    this.menuTarget.appendChild(noResultsOption);
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

  // Autocomplete events

  #filterOptions() {
    this.#filter = this.triggerTarget.value;
    const filter = this.#filter.toLowerCase();
    this.#filteredOptions = [];
    this.menuTarget.innerHTML = "";

    this.#allOptions.forEach((allOption) => {
      let flag = false;
      const category = allOption.cloneNode(true);
      this.#addMenuOptionEventListeners(category);

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
        this.menuTarget.appendChild(category);
      }
    });

    const option = this.#populateCurrentFirstLastOptions();
    if (option === null) {
      this.#renderNoResults();
    }
    if (super.isVisible()) {
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

  #setOption(option) {
    this.#option = option;
    setActiveDescendant(option, this.triggerTarget);
    this.#filteredOptions.forEach((opt) => {
      if (opt === option) {
        opt.setAttribute("aria-selected", "true");
        option.scrollIntoView({ behavior: "smooth", block: "nearest" });
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

  // Trigger events

  #onTriggerKeyDown(event) {
    let flag = false;
    const altKey = event.altKey;

    if (event.ctrlKey || event.shiftKey) {
      return;
    }

    switch (event.key) {
      case "Enter":
        this.debouncedFilterAndUpdate.flush();
        this.#setValue(this.#option);
        super.hide();
        flag = true;
        break;

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
          if (!super.isVisible()) {
            super.show();
          }
        }
        flag = true;
        break;

      case "Up":
      case "ArrowUp":
        if (this.#hasOptions()) {
          if (super.isVisible()) {
            this.#setOption(this.#getPreviousOption(this.#option));
          } else {
            super.show();
            if (!altKey) {
              this.#setOption(this.#lastOption);
            }
          }
        }
        flag = true;
        break;

      case "Esc":
      case "Escape":
        if (super.isVisible()) {
          super.hide();
        } else {
          this.#setValue();
          this.#setOption(null);
        }
        flag = true;
        break;

      case "Tab":
        this.debouncedFilterAndUpdate.flush();
        if (super.isVisible()) {
          this.#setValue(this.#option);
          super.hide();
        }
        break;

      case "Home":
        this.triggerTarget.setSelectionRange(0, 0);
        flag = true;
        break;

      case "End": {
        const length = this.triggerTarget.value.length;
        this.triggerTarget.setSelectionRange(length, length);
        flag = true;
        break;
      }

      default:
        break;
    }

    if (flag) {
      event.stopPropagation();
      event.preventDefault();
    }
  }

  #onTriggerKeyUp(event) {
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

  #onTriggerFocus() {
    this.#filterOptions();
  }

  #onBackgroundMouseDown(event) {
    if (
      !this.triggerTarget.contains(event.target) &&
      !this.menuTarget.contains(event.target)
    ) {
      this.debouncedFilterAndUpdate.flush();
      this.#setValue(this.#option);
      super.hide();
    }
  }

  // Menu Option events

  #onOptionClick(event) {
    const option = event.target.closest('[role="option"]');
    if (option) {
      this.#setValue(option);
      this.#setOption(option);
      super.hide();
      this.triggerTarget.focus();
    }
  }

  // Event handlers

  #addTriggerEventListeners(trigger) {
    trigger.addEventListener("keydown", this.boundOnTriggerKeyDown);
    trigger.addEventListener("keyup", this.boundOnTriggerKeyUp);
    trigger.addEventListener("focus", this.boundOnTriggerFocus);
  }

  #removeTriggerEventListeners(trigger) {
    trigger.removeEventListener("keydown", this.boundOnTriggerKeyDown);
    trigger.removeEventListener("keyup", this.boundOnTriggerKeyUp);
    trigger.removeEventListener("focus", this.boundOnTriggerFocus);
  }

  #addMenuOptionEventListeners(option) {
    option.addEventListener("click", this.boundOnOptionClick);
  }

  #removeMenuOptionEventListeners(option) {
    option.removeEventListener("click", this.boundOnOptionClick);
  }
}
