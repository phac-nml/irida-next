import { Controller } from "@hotwired/stimulus";
import _ from "lodash";

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
  static targets = ["combobox", "listbox", "hidden"];

  connect() {
    this.filter = "";
    this.filteredOptions = [];
    this.allOptions = [];
    this.option = null;
    this.firstOption = null;
    this.lastOption = null;

    // Add debounced filter for search input
    this.debouncedFilterAndUpdate = _.debounce(() => {
      const option = this.#filterOptions();
      if (option) {
        if (this.#isClosed() && this.comboboxTarget.value.length) {
          this.#open();
        }
        if (
          this.#getLowercaseContent(option).indexOf(
            this.comboboxTarget.value.toLowerCase(),
          ) >= 0
        ) {
          this.#setOption(option);
        } else {
          this.#setOption(null);
        }
      }
    }, 300);

    // Add event handlers
    document.body.addEventListener(
      "pointerup",
      this.#onBackgroundPointerUp.bind(this),
      true,
    );

    this.#addComboboxEventListeners(this.comboboxTarget);

    this.#attachOptionEvents(this.listboxTarget, true);
    const categories = this.listboxTarget.querySelectorAll('[role="group"]');
    for (let i = 0; i < categories.length; i++) {
      const category = categories[i];
      this.allOptions.push(category);
      this.#attachOptionEvents(category);
    }
  }

  disconnect() {
    // Remove event handlers
    document.body.removeEventListener(
      "pointerup",
      this.#onBackgroundPointerUp.bind(this),
      true,
    );

    this.#removeComboboxEventListeners(this.comboboxTarget);

    this.#removeOptionEvents(this.listboxTarget);
    const categories = this.listboxTarget.querySelectorAll('[role="group"]');
    for (let i = 0; i < categories.length; i++) {
      const category = categories[i];
      this.#removeOptionEvents(category);
    }
  }

  #attachOptionEvents(category, add = false) {
    const categoryItems = category.querySelectorAll(':scope > [role="option"]');
    for (let i = 0; i < categoryItems.length; i++) {
      const categoryItem = categoryItems[i];
      if (add) {
        this.allOptions.push(categoryItem);
      }
      this.#addListboxOptionEventListeners(categoryItem);
    }
  }

  #removeOptionEvents(category) {
    const categoryItems = category.querySelectorAll(':scope > [role="option"]');
    for (let i = 0; i < categoryItems.length; i++) {
      const categoryItem = categoryItems[i];
      this.#removeListboxOptionEventListeners(categoryItem);
    }
  }

  #getLowercaseContent(node) {
    return node.textContent.toLowerCase();
  }

  #isOptionInView(option) {
    const bounding = option.getBoundingClientRect();
    return (
      bounding.top >= 0 &&
      bounding.left >= 0 &&
      bounding.bottom <=
        (window.innerHeight || document.documentElement.clientHeight) &&
      bounding.right <=
        (window.innerWidth || document.documentElement.clientWidth)
    );
  }

  #setActiveDescendant(option) {
    if (option) {
      this.comboboxTarget.setAttribute("aria-activedescendant", option.id);
      if (!this.#isOptionInView(option)) {
        option.scrollIntoView({ behavior: "smooth", block: "nearest" });
      }
    } else {
      this.comboboxTarget.removeAttribute("aria-activedescendant");
    }
  }

  #setValue(option) {
    this.hiddenTarget.value = option ? option.getAttribute("data-value") : "";
    this.filter = option ? option.textContent : "";
    this.comboboxTarget.value = this.filter;
    this.comboboxTarget.setSelectionRange(
      this.filter.length,
      this.filter.length,
    );
    this.#filterOptions();
    this.#setOption(null);
  }

  // ComboboxAutocomplete events

  #escapeRegExp(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  }

  #filterOptions() {
    let option = null;
    const currentOption = this.option;
    const filter = this.filter.toLowerCase();

    this.filteredOptions = [];
    this.listboxTarget.innerHTML = "";

    for (let i = 0; i < this.allOptions.length; i++) {
      let flag = false;
      const optionCategory = this.allOptions[i].cloneNode(true);

      if (optionCategory.role === "group") {
        const options = optionCategory.querySelectorAll('[role="option"]');
        for (let j = 0; j < options.length; j++) {
          option = options[j];
          this.#addListboxOptionEventListeners(option);
          if (
            filter.length === 0 ||
            this.#getLowercaseContent(option).indexOf(filter) >= 0
          ) {
            flag = true;
            const regex = new RegExp(
              `(${this.#escapeRegExp(this.filter)})`,
              "gi",
            );
            option.innerHTML = option.textContent.replace(
              regex,
              "<mark class='bg-primary-300 dark:bg-primary-600 font-semibold'>$1</mark>",
            );
            this.filteredOptions.push(option);
          } else {
            optionCategory.removeChild(option);
          }
        }
      } else {
        this.#addListboxOptionEventListeners(optionCategory);
        if (
          filter.length === 0 ||
          this.#getLowercaseContent(optionCategory).indexOf(filter) >= 0
        ) {
          flag = true;
          const regex = new RegExp(
            `(${this.#escapeRegExp(this.filter)})`,
            "gi",
          );
          optionCategory.innerHTML = optionCategory.textContent.replace(
            regex,
            "<mark class='bg-primary-300 dark:bg-primary-600 font-semibold'>$1</mark>",
          );
          this.filteredOptions.push(optionCategory);
        }
      }

      if (flag) {
        this.listboxTarget.appendChild(optionCategory);
      }
    }

    // Populate firstOption and lastOption
    const numItems = this.filteredOptions.length;
    if (numItems > 0) {
      this.firstOption = this.filteredOptions[0];
      this.lastOption = this.filteredOptions[numItems - 1];

      if (currentOption && this.filteredOptions.indexOf(currentOption) >= 0) {
        option = currentOption;
      } else {
        option = this.firstOption;
      }
    } else {
      this.firstOption = null;
      option = null;
      this.lastOption = null;
    }

    return option;
  }

  #setOption(option) {
    this.option = option;
    this.#setActiveDescendant(option);

    for (let i = 0; i < this.filteredOptions.length; i++) {
      const opt = this.filteredOptions[i];

      if (opt === option) {
        opt.setAttribute("aria-selected", "true");
        if (!this.#isOptionInView(option)) {
          option.scrollIntoView({ behavior: "smooth", block: "nearest" });
        }
      } else {
        opt.removeAttribute("aria-selected");
      }
    }
  }

  #getPreviousOption(currentOption) {
    if (currentOption !== this.firstOption) {
      const index = this.filteredOptions.indexOf(currentOption);
      return this.filteredOptions[index - 1];
    }
    return this.lastOption;
  }

  #getNextOption(currentOption) {
    if (currentOption !== this.lastOption) {
      const index = this.filteredOptions.indexOf(currentOption);
      return this.filteredOptions[index + 1];
    }
    return this.firstOption;
  }

  // Menu display methods

  #isOpen() {
    return this.listboxTarget.style.display === "block";
  }

  #isClosed() {
    return this.listboxTarget.style.display !== "block";
  }

  #hasOptions() {
    return this.filteredOptions.length;
  }

  #open() {
    this.listboxTarget.style.display = "block";
    this.comboboxTarget.setAttribute("aria-expanded", "true");
  }

  #close() {
    this.#setOption(null);
    this.listboxTarget.style.display = "none";
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
        this.#setValue(this.option);
        this.#close();
        flag = true;
        break;

      case "Down":
      case "ArrowDown":
        if (this.filteredOptions.length > 0) {
          if (altKey && this.#isClosed()) {
            this.#open();
          } else {
            if (this.#isClosed()) {
              this.#open();
            }
            if (this.filteredOptions.length > 1) {
              this.#setOption(this.#getNextOption(this.option));
            } else {
              this.#setOption(this.firstOption);
            }
          }
        }
        flag = true;
        break;

      case "Up":
      case "ArrowUp":
        if (this.#hasOptions()) {
          if (this.#isOpen()) {
            this.#setOption(this.#getPreviousOption(this.option));
          } else {
            this.#open();
            if (!altKey) {
              this.#setOption(this.lastOption);
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
        }
        flag = true;
        break;

      case "Tab":
        this.#close();
        if (this.option) {
          this.#setValue(this.option);
        }
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

  #isPrintableCharacter(str) {
    return str.length === 1 && str.match(/\S| /);
  }

  #onComboboxKeyUp(event) {
    let flag = false,
      option = null,
      char = event.key;

    if (this.#isPrintableCharacter(char)) {
      this.filter += char;
    }

    if (event.key === "Escape" || event.key === "Esc") {
      return;
    }

    switch (event.key) {
      case "Backspace":
        this.filter = this.comboboxTarget.value;
        this.#filterOptions();
        this.#setOption(null);
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
        if (this.#isPrintableCharacter(char)) {
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
    this.filter = this.comboboxTarget.value;
    this.#filterOptions();
    this.#setOption(null);
  }

  #onComboboxBlur() {
    this.#setOption(null);
  }

  #onBackgroundPointerUp(event) {
    if (
      !this.comboboxTarget.contains(event.target) &&
      !this.listboxTarget.contains(event.target)
    ) {
      this.#close();
    }
  }

  // Listbox Option events

  #onOptionClick(event) {
    this.#setValue(event.target);
    this.#close();
  }

  // Event handlers

  #addComboboxEventListeners(combobox) {
    combobox.addEventListener("keydown", this.#onComboboxKeyDown.bind(this));
    combobox.addEventListener("keyup", this.#onComboboxKeyUp.bind(this));
    combobox.addEventListener("click", this.#onComboboxClick.bind(this));
    combobox.addEventListener("focus", this.#onComboboxFocus.bind(this));
    combobox.addEventListener("blur", this.#onComboboxBlur.bind(this));
  }

  #removeComboboxEventListeners(combobox) {
    combobox.removeEventListener("keydown", this.#onComboboxKeyDown.bind(this));
    combobox.removeEventListener("keyup", this.#onComboboxKeyUp.bind(this));
    combobox.removeEventListener("click", this.#onComboboxClick.bind(this));
    combobox.removeEventListener("focus", this.#onComboboxFocus.bind(this));
    combobox.removeEventListener("blur", this.#onComboboxBlur.bind(this));
  }

  #addListboxOptionEventListeners(option) {
    option.addEventListener("click", this.#onOptionClick.bind(this));
  }

  #removeListboxOptionEventListeners(option) {
    option.removeEventListener("click", this.#onOptionClick.bind(this));
  }
}
