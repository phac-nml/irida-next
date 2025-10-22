import { Controller } from "@hotwired/stimulus";

/**
 * SelectWithAutoCompleteController
 *
 * Accessible, searchable dropdown with keyboard navigation.
 * - Keyboard navigation (Arrow keys, Enter, Escape, Home, End)
 * - Search filtering
 * - ARIA roles and attributes for accessibility
 * - Dropdown positioning and focus management
 * - Submit button enable/disable logic
 */
export default class SelectWithAutoCompleteController extends Controller {
  static targets = ["combobox", "listbox", "button"];

  connect() {
    console.debug("SelectWithAutoCompleteController: Connected");
  }

  disconnect() {
    console.debug("SelectWithAutoCompleteController: Disconnected");
  }

  initialize() {
    console.debug("SelectWithAutoCompleteController: Initialize");

    this.comboboxHasVisualFocus = false;
    this.listboxHasVisualFocus = false;

    this.hasHover = false;

    this.allOptions = [];

    this.option = null;
    this.firstOption = null;
    this.lastOption = null;

    this.filteredOptions = [];
    this.filter = "";

    /* add event handlers */
    document.body.addEventListener(
      "pointerup",
      this.onBackgroundPointerUp.bind(this),
      true,
    );
    this.buttonTarget.addEventListener("click", this.onButtonClick.bind(this));
    this.addComboboxEventListeners(this.comboboxTarget);
    this.addListboxEventListeners(this.listboxTarget);

    var categories = this.listboxTarget.getElementsByTagName("ul");
    for (var i = 0; i < categories.length; i++) {
      var category = categories[i];
      this.allOptions.push(category);
      var categoryItems = category.querySelectorAll('li[role="option"]');
      for (var j = 0; j < categoryItems.length; j++) {
        var categoryItem = categoryItems[j];
        this.addListboxOptionEventListeners(categoryItem);
      }
    }

    this.filterOptions();
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
    if (option && this.listboxHasVisualFocus) {
      this.comboboxTarget.setAttribute("aria-activedescendant", option.id);
      if (!this.isOptionInView(option)) {
        option.scrollIntoView({ behavior: "smooth", block: "nearest" });
      }
    } else {
      this.comboboxTarget.setAttribute("aria-activedescendant", "");
    }
  }

  setValue(value) {
    this.filter = value;
    this.comboboxTarget.value = this.filter;
    this.comboboxTarget.setSelectionRange(
      this.filter.length,
      this.filter.length,
    );
    this.filterOptions();
  }

  setOption(option, flag) {
    if (typeof flag !== "boolean") {
      flag = false;
    }

    if (option) {
      this.option = option;
      this.setCurrentOptionStyle(this.option);
      this.setActiveDescendant(this.option);

      this.comboboxTarget.value = this.option.textContent;
      if (flag) {
        this.comboboxTarget.setSelectionRange(
          this.option.textContent.length,
          this.option.textContent.length,
        );
      } else {
        this.comboboxTarget.setSelectionRange(
          this.filter.length,
          this.option.textContent.length,
        );
      }
    }
  }

  setVisualFocusCombobox() {
    this.listboxTarget.classList.remove("focus");
    this.comboboxTarget.parentNode.classList.add("focus");
    this.comboboxHasVisualFocus = true;
    this.listboxHasVisualFocus = false;
    this.setActiveDescendant(false);
  }

  setVisualFocusListbox() {
    this.comboboxTarget.parentNode.classList.remove("focus");
    this.comboboxHasVisualFocus = false;
    this.listboxHasVisualFocus = true;
    this.listboxTarget.classList.add("focus");
    this.setActiveDescendant(this.option);
  }

  removeVisualFocusAll() {
    this.comboboxTarget.parentNode.classList.remove("focus");
    this.comboboxHasVisualFocus = false;
    this.listboxHasVisualFocus = false;
    this.listboxTarget.classList.remove("focus");
    this.option = null;
    this.setActiveDescendant(false);
  }

  // ComboboxAutocomplete Events

  filterOptions() {
    var option = null;
    var currentOption = this.option;
    var filter = this.filter.toLowerCase();

    this.filteredOptions = [];
    this.listboxTarget.innerHTML = "";

    for (var i = 0; i < this.allOptions.length; i++) {
      var optionCategory = this.allOptions[i].cloneNode(true);
      this.addListboxEventListeners(optionCategory);
      var options = optionCategory.querySelectorAll('li[role="option"]');
      var flag = false;

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

      if (flag) {
        this.listboxTarget.appendChild(optionCategory);
      }
    }

    // Use populated options array to initialize firstOption and lastOption.
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

  setCurrentOptionStyle(option) {
    for (var i = 0; i < this.filteredOptions.length; i++) {
      var opt = this.filteredOptions[i];
      if (opt === option) {
        opt.setAttribute("aria-selected", "true");
        if (
          this.listboxTarget.scrollTop + this.listboxTarget.offsetHeight <
          opt.offsetTop + opt.offsetHeight
        ) {
          this.listboxTarget.scrollTop =
            opt.offsetTop + opt.offsetHeight - this.listboxTarget.offsetHeight;
        } else if (this.listboxTarget.scrollTop > opt.offsetTop + 2) {
          this.listboxTarget.scrollTop = opt.offsetTop;
        }
      } else {
        opt.removeAttribute("aria-selected");
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

  doesOptionHaveFocus() {
    return this.comboboxTarget.getAttribute("aria-activedescendant") !== "";
  }

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
    this.buttonTarget.setAttribute("aria-expanded", "true");
  }

  close(force) {
    if (typeof force !== "boolean") {
      force = false;
    }

    if (
      force ||
      (!this.comboboxHasVisualFocus &&
        !this.listboxHasVisualFocus &&
        !this.hasHover)
    ) {
      this.setCurrentOptionStyle(false);
      this.listboxTarget.style.display = "none";
      this.comboboxTarget.setAttribute("aria-expanded", "false");
      this.buttonTarget.setAttribute("aria-expanded", "false");
      this.setActiveDescendant(false);
      this.comboboxTarget.parentNode.classList.add("focus");
    }
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
        if (this.listboxHasVisualFocus) {
          this.setValue(this.option.textContent);
        }
        this.close(true);
        this.setVisualFocusCombobox();
        flag = true;
        break;

      case "Down":
      case "ArrowDown":
        if (this.filteredOptions.length > 0) {
          if (altKey) {
            this.open();
          } else {
            this.open();
            if (
              this.listboxHasVisualFocus ||
              (this.isBoth && this.filteredOptions.length > 1)
            ) {
              this.setOption(this.getNextOption(this.option), true);
              this.setVisualFocusListbox();
            } else {
              this.setOption(this.firstOption, true);
              this.setVisualFocusListbox();
            }
          }
        }
        flag = true;
        break;

      case "Up":
      case "ArrowUp":
        if (this.hasOptions()) {
          if (this.listboxHasVisualFocus) {
            this.setOption(this.getPreviousOption(this.option), true);
          } else {
            this.open();
            if (!altKey) {
              this.setOption(this.lastOption, true);
              this.setVisualFocusListbox();
            }
          }
        }
        flag = true;
        break;

      case "Esc":
      case "Escape":
        if (this.isOpen()) {
          this.close(true);
          this.filter = this.comboboxTarget.value;
          this.filterOptions();
          this.setVisualFocusCombobox();
        } else {
          this.setValue("");
          this.comboboxTarget.value = "";
        }
        this.option = null;
        flag = true;
        break;

      case "Tab":
        this.close(true);
        if (this.listboxHasVisualFocus) {
          if (this.option) {
            this.setValue(this.option.textContent);
          }
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

    // this is for the case when a selection in the textbox has been deleted
    if (this.comboboxTarget.value.length < this.filter.length) {
      this.filter = this.comboboxTarget.value;
      this.option = null;
      this.filterOptions();
    }

    if (event.key === "Escape" || event.key === "Esc") {
      return;
    }

    switch (event.key) {
      case "Backspace":
        this.setVisualFocusCombobox();
        this.setCurrentOptionStyle(false);
        this.filter = this.comboboxTarget.value;
        this.option = null;
        this.filterOptions();
        flag = true;
        break;

      case "Left":
      case "ArrowLeft":
      case "Right":
      case "ArrowRight":
      case "Home":
      case "End":
        if (this.isBoth) {
          this.filter = this.comboboxTarget.value;
        } else {
          this.option = null;
          this.setCurrentOptionStyle(false);
        }
        this.setVisualFocusCombobox();
        flag = true;
        break;

      default:
        if (this.isPrintableCharacter(char)) {
          this.setVisualFocusCombobox();
          this.setCurrentOptionStyle(false);
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
              this.option = option;
              if (this.isBoth || this.listboxHasVisualFocus) {
                this.setCurrentOptionStyle(option);
                if (this.isBoth) {
                  this.setOption(option);
                }
              }
            } else {
              this.option = null;
              this.setCurrentOptionStyle(false);
            }
          } else {
            this.close();
            this.option = null;
            this.setActiveDescendant(false);
          }
        } else if (this.comboboxTarget.value.length) {
          this.open();
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
      this.close(true);
    } else {
      this.open();
    }
  }

  onComboboxFocus() {
    this.filter = this.comboboxTarget.value;
    this.filterOptions();
    this.setVisualFocusCombobox();
    this.option = null;
    this.setCurrentOptionStyle(null);
  }

  onComboboxBlur() {
    this.removeVisualFocusAll();
  }

  onBackgroundPointerUp(event) {
    if (
      !this.comboboxTarget.contains(event.target) &&
      !this.listboxTarget.contains(event.target) &&
      !this.buttonTarget.contains(event.target)
    ) {
      this.comboboxHasVisualFocus = false;
      this.setCurrentOptionStyle(null);
      this.removeVisualFocusAll();
      setTimeout(this.close.bind(this, true), 300);
    }
  }

  onButtonClick() {
    if (this.isOpen()) {
      this.close(true);
    } else {
      this.open();
    }
    this.comboboxTarget.focus();
    this.setVisualFocusCombobox();
  }

  // Listbox events

  onListboxPointerover() {
    this.hasHover = true;
  }

  onListboxPointerout() {
    this.hasHover = false;
    setTimeout(this.close.bind(this, false), 300);
  }

  // Listbox Option events

  onOptionClick(event) {
    this.comboboxTarget.value = event.target.textContent;
    this.close(true);
  }

  onOptionPointerover() {
    this.hasHover = true;
    this.open();
  }

  onOptionPointerout() {
    this.hasHover = false;
    setTimeout(this.close.bind(this, false), 300);
  }

  // Event handlers
  addComboboxEventListeners(combobox) {
    combobox.addEventListener("keydown", this.onComboboxKeyDown.bind(this));
    combobox.addEventListener("keyup", this.onComboboxKeyUp.bind(this));
    combobox.addEventListener("click", this.onComboboxClick.bind(this));
    combobox.addEventListener("focus", this.onComboboxFocus.bind(this));
    combobox.addEventListener("blur", this.onComboboxBlur.bind(this));
  }

  addListboxEventListeners(listbox) {
    listbox.addEventListener(
      "pointerover",
      this.onListboxPointerover.bind(this),
    );
    listbox.addEventListener("pointerout", this.onListboxPointerout.bind(this));
  }

  addListboxOptionEventListeners(option) {
    option.addEventListener("click", this.onOptionClick.bind(this));
    option.addEventListener("pointerover", this.onOptionPointerover.bind(this));
    option.addEventListener("pointerout", this.onOptionPointerout.bind(this));
  }
}
