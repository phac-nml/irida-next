import { Controller } from "@hotwired/stimulus";

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
    this.allOptions = [];

    this.option = null;
    this.firstOption = null;
    this.lastOption = null;

    this.filteredOptions = [];
    this.filter = "";

    // Add event handlers
    document.body.addEventListener(
      "pointerup",
      this.onBackgroundPointerUp.bind(this),
      true,
    );
    this.addComboboxEventListeners(this.comboboxTarget);

    this.attachOptionEvents(this.listboxTarget, true);
    var categories = this.listboxTarget.querySelectorAll('[role="group"]');
    for (var i = 0; i < categories.length; i++) {
      var category = categories[i];
      this.allOptions.push(category);
      this.attachOptionEvents(category);
    }
  }

  attachOptionEvents(category, add = false) {
    var categoryItems = category.querySelectorAll(':scope > [role="option"]');
    for (var i = 0; i < categoryItems.length; i++) {
      var categoryItem = categoryItems[i];
      if (add) {
        this.allOptions.push(categoryItem);
      }
      this.addListboxOptionEventListeners(categoryItem);
    }
  }

  getLowercaseContent(node) {
    return node.textContent.toLowerCase();
  }

  isOptionInView(option) {
    var bounding = option.getBoundingClientRect();
    return (
      bounding.top >= 0 &&
      bounding.left >= 0 &&
      bounding.bottom <=
        (window.innerHeight || document.documentElement.clientHeight) &&
      bounding.right <=
        (window.innerWidth || document.documentElement.clientWidth)
    );
  }

  setActiveDescendant(option) {
    if (option) {
      this.comboboxTarget.setAttribute("aria-activedescendant", option.id);
      if (!this.isOptionInView(option)) {
        option.scrollIntoView({ behavior: "smooth", block: "nearest" });
      }
    } else {
      this.comboboxTarget.setAttribute("aria-activedescendant", "");
    }
  }

  setValue(option) {
    this.hiddenTarget.value = option ? option.getAttribute("data-value") : "";
    this.filter = option ? option.textContent : "";
    this.comboboxTarget.value = this.filter;
    this.comboboxTarget.setSelectionRange(
      this.filter.length,
      this.filter.length,
    );
    this.filterOptions();
    this.setOption(null);
  }

  // ComboboxAutocomplete events

  filterOptions() {
    var option = null;
    var currentOption = this.option;
    var filter = this.filter.toLowerCase();

    this.filteredOptions = [];
    this.listboxTarget.innerHTML = "";

    for (var i = 0; i < this.allOptions.length; i++) {
      var flag = false;
      var optionCategory = this.allOptions[i].cloneNode(true);

      if (optionCategory.role === "group") {
        var options = optionCategory.querySelectorAll('[role="option"]');
        for (var j = 0; j < options.length; j++) {
          option = options[j];
          this.addListboxOptionEventListeners(option);
          if (
            filter.length === 0 ||
            this.getLowercaseContent(option).indexOf(filter) === 0
          ) {
            flag = true;
            this.filteredOptions.push(option);
          } else {
            optionCategory.removeChild(option);
          }
        }
      } else {
        // assume presentation & option role
        this.addListboxOptionEventListeners(optionCategory);
        if (
          filter.length === 0 ||
          this.getLowercaseContent(optionCategory).indexOf(filter) === 0
        ) {
          flag = true;
          this.filteredOptions.push(optionCategory);
        }
      }

      if (flag) {
        this.listboxTarget.appendChild(optionCategory);
      }
    }

    // Populate firstOption and lastOption
    var numItems = this.filteredOptions.length;
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

  setOption(option) {
    if (option) {
      this.option = option;
      this.setActiveDescendant(option);

      for (var i = 0; i < this.filteredOptions.length; i++) {
        var opt = this.filteredOptions[i];
        if (opt === option) {
          opt.setAttribute("aria-selected", "true");
          if (
            this.listboxTarget.scrollTop + this.listboxTarget.offsetHeight <
            opt.offsetTop + opt.offsetHeight
          ) {
            this.listboxTarget.scrollTop =
              opt.offsetTop +
              opt.offsetHeight -
              this.listboxTarget.offsetHeight;
          } else if (this.listboxTarget.scrollTop > opt.offsetTop + 2) {
            this.listboxTarget.scrollTop = opt.offsetTop;
          }
        } else {
          opt.removeAttribute("aria-selected");
        }
      }
    }
  }

  getPreviousOption(currentOption) {
    if (currentOption !== this.firstOption) {
      var index = this.filteredOptions.indexOf(currentOption);
      return this.filteredOptions[index - 1];
    }
    return this.lastOption;
  }

  getNextOption(currentOption) {
    if (currentOption !== this.lastOption) {
      var index = this.filteredOptions.indexOf(currentOption);
      return this.filteredOptions[index + 1];
    }
    return this.firstOption;
  }

  // Menu display methods

  isOpen() {
    return this.listboxTarget.style.display === "block";
  }

  isClosed() {
    return this.listboxTarget.style.display !== "block";
  }

  hasOptions() {
    return this.filteredOptions.length;
  }

  open() {
    this.listboxTarget.style.display = "block";
    this.comboboxTarget.setAttribute("aria-expanded", "true");
  }

  close() {
    this.setOption(null);
    this.listboxTarget.style.display = "none";
    this.comboboxTarget.setAttribute("aria-expanded", "false");
  }

  // Combobox events

  onComboboxKeyDown(event) {
    var flag = false,
      altKey = event.altKey;

    if (event.ctrlKey || event.shiftKey) {
      return;
    }

    switch (event.key) {
      case "Enter":
        this.setValue(this.option);
        this.close();
        flag = true;
        break;

      case "Down":
      case "ArrowDown":
        if (this.filteredOptions.length > 0) {
          if (altKey && this.isClosed()) {
            this.open();
          } else {
            if (this.isClosed()) {
              this.open();
            }
            if (this.filteredOptions.length > 1) {
              this.setOption(this.getNextOption(this.option), true);
            } else {
              this.setOption(this.firstOption, true);
            }
          }
        }
        flag = true;
        break;

      case "Up":
      case "ArrowUp":
        if (this.hasOptions()) {
          if (this.isOpen()) {
            this.setOption(this.getPreviousOption(this.option), true);
          } else {
            this.open();
            if (!altKey) {
              this.setOption(this.lastOption, true);
            }
          }
        }
        flag = true;
        break;

      case "Esc":
      case "Escape":
        if (this.isOpen()) {
          this.close();
        } else {
          this.setValue();
        }
        flag = true;
        break;

      case "Tab":
        this.close();
        if (this.option) {
          this.setValue(this.option);
        }
        break;

      case "Home":
        this.comboboxTarget.setSelectionRange(0, 0);
        flag = true;
        break;

      case "End":
        var length = this.comboboxTarget.value.length;
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

  isPrintableCharacter(str) {
    return str.length === 1 && str.match(/\S| /);
  }

  onComboboxKeyUp(event) {
    var flag = false,
      option = null,
      char = event.key;

    if (this.isPrintableCharacter(char)) {
      this.filter += char;
    }

    if (event.key === "Escape" || event.key === "Esc") {
      return;
    }

    switch (event.key) {
      case "Backspace":
        this.filter = this.comboboxTarget.value;
        this.filterOptions();
        this.setOption(null);
        flag = true;
        break;

      case "Left":
      case "ArrowLeft":
      case "Right":
      case "ArrowRight":
      case "Home":
      case "End":
        this.setOption(null);
        flag = true;
        break;

      default:
        if (this.isPrintableCharacter(char)) {
          this.setOption(null);
          flag = true;

          option = this.filterOptions();
          if (option) {
            if (this.isClosed() && this.comboboxTarget.value.length) {
              this.open();
            }

            if (
              this.getLowercaseContent(option).indexOf(
                this.comboboxTarget.value.toLowerCase(),
              ) === 0
            ) {
              this.setOption(option);
            } else {
              this.setOption(null);
            }
          } else {
            const noResults = document.createElement("div");
            noResults.textContent = "No results found";
            this.listboxTarget.appendChild(noResults);
          }
        }

        break;
    }

    if (flag) {
      event.stopPropagation();
      event.preventDefault();
    }
  }

  onComboboxClick() {
    if (this.isOpen()) {
      this.close();
    } else {
      this.open();
    }
  }

  onComboboxFocus() {
    this.filter = this.comboboxTarget.value;
    this.filterOptions();
    this.setOption(null);
  }

  onComboboxBlur() {
    this.setOption(null);
  }

  onBackgroundPointerUp(event) {
    if (
      !this.comboboxTarget.contains(event.target) &&
      !this.listboxTarget.contains(event.target)
    ) {
      this.close.bind(this, true);
    }
  }

  // Listbox Option events

  onOptionClick(event) {
    this.setValue(event.target);
    this.close();
  }

  // Event handlers

  addComboboxEventListeners(combobox) {
    combobox.addEventListener("keydown", this.onComboboxKeyDown.bind(this));
    combobox.addEventListener("keyup", this.onComboboxKeyUp.bind(this));
    combobox.addEventListener("click", this.onComboboxClick.bind(this));
    combobox.addEventListener("focus", this.onComboboxFocus.bind(this));
    combobox.addEventListener("blur", this.onComboboxBlur.bind(this));
  }

  addListboxOptionEventListeners(option) {
    option.addEventListener("click", this.onOptionClick.bind(this));
  }
}
