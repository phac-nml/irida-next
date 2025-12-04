import { Controller } from "@hotwired/stimulus";
import _ from "lodash";
import {
  isPrintableCharacter,
  getLowercaseContent,
  isOptionInView,
  highlightOption,
  setActiveDescendant,
} from "controllers/select_with_auto_complete/utils";

/**
 * SelectWithAutoCompleteController
 *
 * Accessible, searchable dropdown with keyboard navigation.
 * - Keyboard navigation (Arrow keys, Enter, Escape, Home, End)
 * - Search filtering
 * - ARIA roles and attributes for accessibility
 * - Dropdown positioning and focus management
 */
export default class SelectWithAutoCompleteController extends Controller {
  static targets = ["combobox", "listbox", "hidden", "ariaLiveUpdate"];
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
    this.boundOnBackgroundPointerUp = this.#onBackgroundPointerUp.bind(this);
    this.boundOnComboboxKeyDown = this.#onComboboxKeyDown.bind(this);
    this.boundOnComboboxKeyUp = this.#onComboboxKeyUp.bind(this);
    this.boundOnComboboxClick = this.#onComboboxClick.bind(this);
    this.boundOnComboboxFocus = this.#onComboboxFocus.bind(this);
    this.boundOnComboboxBlur = this.#onComboboxBlur.bind(this);
    this.boundOnOptionClick = this.#onOptionClick.bind(this);

    this.#filter = "";
    this.#filteredOptions = [];
    this.#allOptions = [];
    this.#option = null;
    this.#firstOption = null;
    this.#lastOption = null;

    // Add debounced filter for search input
    this.debouncedFilterAndUpdate = _.debounce(() => {
      const option = this.#filterOptions();
      if (this.#isClosed() && this.comboboxTarget.value.length) {
        this.#open();
      }
      this.#setOption(option);
    }, 300);

    // Add event handlers
    document.body.addEventListener(
      "pointerup",
      this.boundOnBackgroundPointerUp,
      true,
    );

    this.#addComboboxEventListeners(this.comboboxTarget);

    this.#attachOptionEvents(this.listboxTarget, true);
    const categories = this.listboxTarget.querySelectorAll('[role="group"]');
    categories.forEach((category) => {
      this.#allOptions.push(category);
      this.#attachOptionEvents(category);
    });
  }

  disconnect() {
    // Remove event handlers
    document.body.removeEventListener(
      "pointerup",
      this.boundOnBackgroundPointerUp,
      true,
    );

    this.#removeComboboxEventListeners(this.comboboxTarget);

    this.#removeOptionEvents(this.listboxTarget);
    const categories = this.listboxTarget.querySelectorAll('[role="group"]');
    categories.forEach((category) => {
      this.#removeOptionEvents(category);
    });
  }

  #attachOptionEvents(category, add = false) {
    const categoryItems = category.querySelectorAll(':scope > [role="option"]');
    categoryItems.forEach((categoryItem) => {
      if (add) {
        this.#allOptions.push(categoryItem);
      }
      this.#addListboxOptionEventListeners(categoryItem);
    });
  }

  #removeOptionEvents(category) {
    const categoryItems = category.querySelectorAll(':scope > [role="option"]');
    categoryItems.forEach((categoryItem) => {
      this.#removeListboxOptionEventListeners(categoryItem);
    });
  }

  #setValue(option) {
    this.hiddenTarget.value = option ? option.getAttribute("data-value") : "";
    this.#filter = option ? option.textContent : "";
    this.comboboxTarget.value = this.#filter;
    this.comboboxTarget.setSelectionRange(
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
    this.listboxTarget.appendChild(noResultsOption);
  }

  #announceNumberOfResults() {
    if (this.hasAriaLiveUpdateTarget) {
      const numItems = this.#filteredOptions.length;
      if (numItems === 0) {
        this.ariaLiveUpdateTarget.textContent = this.noResultsTextValue;
      } else if (numItems === 1) {
        this.ariaLiveUpdateTarget.textContent = this.singleResultTextValue;
      } else {
        this.ariaLiveUpdateTarget.textContent =
          this.multipleResultsTextValue.replace("%{num}", String(numItems));
      }
    }
  }

  // ComboboxAutocomplete events

  #filterOptions() {
    const filter = this.#filter.toLowerCase();
    this.#filteredOptions = [];
    this.listboxTarget.innerHTML = "";

    this.#allOptions.forEach((allOption) => {
      let flag = false;
      const category = allOption.cloneNode(true);

      if (category.role === "group") {
        const categoryOptions = category.querySelectorAll('[role="option"]');
        categoryOptions.forEach((categoryOption) => {
          this.#addListboxOptionEventListeners(categoryOption);
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
        this.#addListboxOptionEventListeners(category);
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
    this.#announceNumberOfResults();

    return option;
  }

  #populateCurrentFirstLastOptions() {
    let option = null;
    const currentOption = this.#option;
    const numItems = this.#filteredOptions.length;

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
    setActiveDescendant(option, this.comboboxTarget);
    this.#filteredOptions.forEach((opt) => {
      if (opt === option) {
        opt.setAttribute("aria-selected", "true");
        if (!isOptionInView(option)) {
          option.scrollIntoView({ behavior: "smooth", block: "nearest" });
        }
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

  #isOpen() {
    return this.listboxTarget.style.display === "block";
  }

  #isClosed() {
    return this.listboxTarget.style.display !== "block";
  }

  #hasOptions() {
    return this.#filteredOptions.length;
  }

  #open() {
    this.listboxTarget.style.display = "block";
    this.listboxTarget.removeAttribute("aria-hidden");
    this.comboboxTarget.setAttribute("aria-expanded", "true");
  }

  #close() {
    this.listboxTarget.style.display = "none";
    this.listboxTarget.setAttribute("aria-hidden", "true");
    this.comboboxTarget.setAttribute("aria-expanded", "false");
  }

  // Combobox events

  #onComboboxKeyDown(event) {
    let flag = false,
      altKey = event.altKey;

    if (event.ctrlKey || event.shiftKey) {
      return;
    }

    switch (event.key) {
      case "Enter":
        this.debouncedFilterAndUpdate.flush();
        this.#setValue(this.#option);
        this.#setOption(this.#option);
        this.#close();
        flag = true;
        break;

      case "Down":
      case "ArrowDown":
        if (this.#filteredOptions.length > 0) {
          if (altKey && this.#isClosed()) {
            this.#open();
          } else {
            if (this.#isClosed()) {
              this.#open();
            }
            if (this.#filteredOptions.length > 1) {
              this.#setOption(this.#getNextOption(this.#option));
            } else {
              this.#setOption(this.#firstOption);
            }
          }
        }
        flag = true;
        break;

      case "Up":
      case "ArrowUp":
        if (this.#hasOptions()) {
          if (this.#isOpen()) {
            this.#setOption(this.#getPreviousOption(this.#option));
          } else {
            this.#open();
            if (!altKey) {
              this.#setOption(this.#lastOption);
            }
          }
        }
        flag = true;
        break;

      case "Esc":
      case "Escape":
        if (this.#isOpen()) {
          this.#close();
        } else {
          this.#setValue();
          this.#setOption(null);
        }
        flag = true;
        break;

      case "Tab":
        if (this.comboboxTarget.value) {
          this.#filter = this.comboboxTarget.value;
          const option = this.#filterOptions();
          this.#setValue(option);
          this.#setOption(option);
        }
        this.#close();
        break;

      case "Home":
        this.comboboxTarget.setSelectionRange(0, 0);
        flag = true;
        break;

      case "End":
        const length = this.comboboxTarget.value.length;
        this.comboboxTarget.setSelectionRange(length, length);
        flag = true;
        break;

      default:
        break;
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
        this.#filter = this.comboboxTarget.value;
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
    if (this.#isOpen()) {
      this.#close();
    } else {
      this.#open();
    }
  }

  #onComboboxFocus() {
    this.#filter = this.comboboxTarget.value;
    this.#filterOptions();
  }

  #onComboboxBlur() {
    this.#filter = this.comboboxTarget.value;
  }

  #onBackgroundPointerUp(event) {
    if (
      !this.comboboxTarget.contains(event.target) &&
      !this.listboxTarget.contains(event.target)
    ) {
      if (this.comboboxTarget.value) {
        this.#filter = this.comboboxTarget.value;
        const option = this.#filterOptions();
        this.#setValue(option);
        this.#setOption(option);
      }
      this.#close();
    }
  }

  // Listbox Option events

  #onOptionClick(event) {
    this.#setValue(event.target);
    this.#setOption(event.target);
    this.#close();
  }

  // Event handlers

  #addComboboxEventListeners(combobox) {
    combobox.addEventListener("keydown", this.boundOnComboboxKeyDown);
    combobox.addEventListener("keyup", this.boundOnComboboxKeyUp);
    combobox.addEventListener("click", this.boundOnComboboxClick);
    combobox.addEventListener("focus", this.boundOnComboboxFocus);
    combobox.addEventListener("blur", this.boundOnComboboxBlur);
  }

  #removeComboboxEventListeners(combobox) {
    combobox.removeEventListener("keydown", this.boundOnComboboxKeyDown);
    combobox.removeEventListener("keyup", this.boundOnComboboxKeyUp);
    combobox.removeEventListener("click", this.boundOnComboboxClick);
    combobox.removeEventListener("focus", this.boundOnComboboxFocus);
    combobox.removeEventListener("blur", this.boundOnComboboxBlur);
  }

  #addListboxOptionEventListeners(option) {
    option.addEventListener("click", this.boundOnOptionClick);
  }

  #removeListboxOptionEventListeners(option) {
    option.removeEventListener("click", this.boundOnOptionClick);
  }
}
