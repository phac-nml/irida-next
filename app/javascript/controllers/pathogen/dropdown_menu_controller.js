import { Controller } from "@hotwired/stimulus";
import {
  autoUpdate,
  computePosition,
  flip,
  offset,
  shift,
} from "@floating-ui/dom";

/**
 * Dropdown Menu Controller
 *
 * Enhances Pathogen::DropdownMenu with:
 * - WAI-ARIA menu button interactions
 * - Keyboard navigation (roving tabindex)
 * - One-level submenus
 * - Floating UI positioning
 * - Snapshot + revert on dismiss (Cancel, Escape, outside click)
 * - Custom events for integration
 *
 * Events:
 * - pathogen:dropdown-menu:change (bubbles)
 * - pathogen:dropdown-menu:cancel (bubbles)
 */
export default class extends Controller {
  static targets = ["trigger", "menu", "item", "input"];

  static values = {
    placement: { type: String, default: "bottom-start" },
    offset: { type: Number, default: 8 },
    autoSubmit: { type: Boolean, default: false },
    submitOnApply: { type: Boolean, default: false },
  };

  #boundOnDocumentPointerDown = null;
  #boundOnKeydown = null;
  #rootCleanupAutoUpdate = null;
  #submenuCleanupAutoUpdate = null;

  #snapshot = null;
  #openSubmenuMenu = null;
  #submenuCloseTimeout = null;

  connect() {
    this.#initializeMenus();

    this.#boundOnDocumentPointerDown = this.#onDocumentPointerDown.bind(this);
    document.addEventListener("pointerdown", this.#boundOnDocumentPointerDown, {
      capture: true,
    });

    this.#boundOnKeydown = this.#onKeydown.bind(this);
    this.element.addEventListener("keydown", this.#boundOnKeydown);
  }

  disconnect() {
    if (this.#boundOnDocumentPointerDown) {
      document.removeEventListener(
        "pointerdown",
        this.#boundOnDocumentPointerDown,
        true,
      );
    }

    if (this.#boundOnKeydown) {
      this.element.removeEventListener("keydown", this.#boundOnKeydown);
    }

    this.#stopAutoUpdate();
    this.cancelScheduledSubmenuClose();
  }

  toggle(event) {
    event.preventDefault();

    if (this.#isRootMenuOpen()) {
      this.cancel({ source: "cancel" });
      return;
    }

    this.open();
  }

  open() {
    const rootMenu = this.#rootMenu();
    if (!rootMenu) return;

    this.#snapshot = this.#captureSnapshot();

    this.#setRootMenuOpen(true);
    this.#positionRootMenu();

    this.#focusFirstItem(rootMenu);
  }

  apply(event) {
    if (event) event.preventDefault();

    const rootMenu = this.#rootMenu();
    if (!rootMenu) return;

    const { name, values, valuesByName } = this.#checkedCheckboxValues();

    this.dispatch("change", {
      prefix: "pathogen:dropdown-menu",
      detail: {
        version: 1,
        mode: "multi",
        name,
        values,
        valuesByName,
        source: "apply",
      },
    });

    if (this.submitOnApplyValue) {
      this.#requestSubmitNearestForm();
    }

    this.close();
  }

  cancel({ source = "cancel" } = {}) {
    this.#revertToSnapshot();

    this.dispatch("cancel", {
      prefix: "pathogen:dropdown-menu",
      detail: {
        version: 1,
        snapshot: this.#snapshot,
        source,
      },
    });

    const restoreFocus = source !== "outside";
    this.close({ restoreFocus });
  }

  close({ restoreFocus = true } = {}) {
    this.cancelScheduledSubmenuClose();
    this.#closeSubmenu();
    this.#setRootMenuOpen(false);
    this.#stopAutoUpdate();

    if (restoreFocus) {
      this.triggerTarget?.focus();
    }
  }

  activate(event) {
    if (event) event.preventDefault();

    const target = event?.currentTarget;
    if (!target) return;

    if (target.getAttribute("aria-disabled") === "true") {
      return;
    }

    // Allow anchors to navigate naturally.
    if (target.tagName.toLowerCase() === "a") {
      this.close({ restoreFocus: false });
      return;
    }

    // For buttons, trigger click-like behavior (Turbo, etc.) and close.
    target.click();
    this.close({ restoreFocus: false });
  }

  toggleCheckbox(event) {
    if (event) event.preventDefault();

    const button = event?.currentTarget;
    if (!button) return;
    if (button.disabled) return;

    const name = button.dataset.name;
    const value = button.dataset.value;

    const input = this.#findInput(name, value);
    if (!input) return;

    input.checked = !input.checked;

    this.#syncCheckboxButton(button, input.checked);

    const { values, valuesByName } = this.#checkedCheckboxValues(name);

    this.dispatch("change", {
      prefix: "pathogen:dropdown-menu",
      detail: {
        version: 1,
        mode: "multi",
        name,
        value,
        checked: input.checked,
        values,
        valuesByName,
        source: "toggle",
      },
    });
  }

  selectRadio(event) {
    if (event) event.preventDefault();

    const button = event?.currentTarget;
    if (!button) return;
    if (button.disabled) return;

    const name = button.dataset.name;
    const value = button.dataset.value;

    const inputs = this.inputTargets.filter(
      (el) => el.type === "radio" && el.name === name,
    );

    inputs.forEach((input) => {
      input.checked = input.value === value;
    });

    this.#syncRadioButtons(name);

    this.dispatch("change", {
      prefix: "pathogen:dropdown-menu",
      detail: {
        version: 1,
        mode: "single",
        name,
        value,
        source: "single",
      },
    });

    if (this.autoSubmitValue) {
      this.#requestSubmitNearestForm();
    }

    this.close({ restoreFocus: false });
  }

  toggleSubmenu(event) {
    if (event) event.preventDefault();

    const trigger = event?.currentTarget;
    if (!trigger) return;
    if (trigger.disabled) return;

    const submenuMenuId = trigger.dataset.submenuMenuId;
    if (!submenuMenuId) return;

    const submenuMenu = this.element.querySelector(
      `#${CSS.escape(submenuMenuId)}`,
    );
    if (!submenuMenu) return;

    if (submenuMenu.hidden) {
      this.#openSubmenu(trigger, submenuMenu);
    } else {
      this.#closeSubmenu();
    }
  }

  openSubmenuOnHover(event) {
    const trigger = event?.currentTarget;
    if (!trigger) return;
    if (trigger.disabled) return;

    if (!this.#isRootMenuOpen()) return;

    const submenuMenuId = trigger.dataset.submenuMenuId;
    if (!submenuMenuId) return;

    const submenuMenu = this.element.querySelector(
      `#${CSS.escape(submenuMenuId)}`,
    );
    if (!submenuMenu) return;

    this.cancelScheduledSubmenuClose();
    this.#openSubmenu(trigger, submenuMenu);
  }

  scheduleCloseSubmenu(event) {
    const trigger = event?.currentTarget;
    if (!trigger) return;

    const submenuMenuId = trigger.dataset.submenuMenuId;
    if (!submenuMenuId) return;

    const submenuMenu = this.element.querySelector(
      `#${CSS.escape(submenuMenuId)}`,
    );
    if (!submenuMenu) return;

    // Only schedule close for the submenu that is currently open.
    if (this.#openSubmenuMenu !== submenuMenu) return;

    // If we're moving directly into the submenu, don't schedule a close.
    const related = event?.relatedTarget;
    if (related && submenuMenu.contains(related)) return;

    this.cancelScheduledSubmenuClose();
    this.#submenuCloseTimeout = window.setTimeout(() => {
      this.#submenuCloseTimeout = null;
      this.#closeSubmenu();
    }, 150);
  }

  cancelScheduledSubmenuClose() {
    if (!this.#submenuCloseTimeout) return;
    window.clearTimeout(this.#submenuCloseTimeout);
    this.#submenuCloseTimeout = null;
  }

  closeSubmenuOnLeave(event) {
    // Close the submenu when the pointer leaves the submenu menu.
    // This keeps submenus hover-friendly without requiring a document-level hover tracker.
    const submenuMenu = event?.currentTarget;
    if (!submenuMenu) return;

    if (this.#openSubmenuMenu === submenuMenu) {
      this.cancelScheduledSubmenuClose();
      this.#closeSubmenu();
    }
  }

  onTriggerKeydown(event) {
    if (!event) return;

    if (event.key === "ArrowDown") {
      event.preventDefault();
      this.open();
      return;
    }

    if (event.key === "ArrowUp") {
      event.preventDefault();
      this.open();
      this.#focusLastItem(this.#rootMenu());
      return;
    }

    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      this.open();
    }
  }

  // Private

  #initializeMenus() {
    // Ensure all menus start in a consistent closed state.
    this.menuTargets.forEach((menu) => {
      menu.dataset.state = "closed";
      menu.hidden = true;
    });

    // Initialize roving tabindex for items.
    this.#initializeRovingTabindex();
  }

  #initializeRovingTabindex() {
    // Set all items to tabindex -1 initially. We set tabindex=0 on the focused item when opening.
    this.itemTargets.forEach((item) => {
      item.tabIndex = -1;
    });
  }

  #rootMenu() {
    return this.menuTargets.find((m) => m.dataset.menuRoot === "true");
  }

  #isRootMenuOpen() {
    const menu = this.#rootMenu();
    return Boolean(menu && !menu.hidden);
  }

  #setRootMenuOpen(isOpen) {
    const menu = this.#rootMenu();
    if (!menu) return;

    menu.hidden = !isOpen;
    menu.dataset.state = isOpen ? "open" : "closed";

    if (this.hasTriggerTarget) {
      this.triggerTarget.setAttribute("aria-expanded", String(isOpen));
    }
  }

  async #positionRootMenu() {
    const menu = this.#rootMenu();
    if (!menu || !this.hasTriggerTarget) return;

    const update = async () => {
      const { x, y } = await computePosition(this.triggerTarget, menu, {
        placement: this.placementValue,
        middleware: [offset(this.offsetValue), flip(), shift({ padding: 8 })],
      });

      Object.assign(menu.style, {
        position: "absolute",
        left: `${x}px`,
        top: `${y}px`,
      });
    };

    await update();

    this.#rootCleanupAutoUpdate = autoUpdate(this.triggerTarget, menu, update);
  }

  async #positionSubmenu(trigger, submenuMenu) {
    const update = async () => {
      const { x, y } = await computePosition(trigger, submenuMenu, {
        placement: "right-start",
        middleware: [offset(4), flip(), shift({ padding: 8 })],
      });

      Object.assign(submenuMenu.style, {
        position: "absolute",
        left: `${x}px`,
        top: `${y}px`,
      });
    };

    await update();

    this.#submenuCleanupAutoUpdate = autoUpdate(trigger, submenuMenu, update);
  }

  #stopAutoUpdate() {
    if (this.#rootCleanupAutoUpdate) {
      this.#rootCleanupAutoUpdate();
      this.#rootCleanupAutoUpdate = null;
    }

    if (this.#submenuCleanupAutoUpdate) {
      this.#submenuCleanupAutoUpdate();
      this.#submenuCleanupAutoUpdate = null;
    }
  }

  #itemsInMenu(menu) {
    if (!menu) return [];

    return Array.from(
      menu.querySelectorAll('[data-pathogen--dropdown-menu-target="item"]'),
    ).filter((el) => !el.closest("[hidden]") && !el.disabled);
  }

  #focusFirstItem(menu) {
    const items = this.#itemsInMenu(menu);
    if (items.length === 0) return;

    this.#setRovingFocus(items[0], items);
  }

  #focusLastItem(menu) {
    if (!menu) return;

    const items = this.#itemsInMenu(menu);
    if (items.length === 0) return;

    this.#setRovingFocus(items[items.length - 1], items);
  }

  #setRovingFocus(nextItem, items) {
    items.forEach((item) => {
      item.tabIndex = item === nextItem ? 0 : -1;
    });

    nextItem.focus();
  }

  #onKeydown(event) {
    if (!this.#isRootMenuOpen()) return;

    const activeElement = document.activeElement;
    const openMenu =
      activeElement?.closest('[role="menu"]') || this.#rootMenu();

    if (event.key === "Escape") {
      event.preventDefault();
      this.cancel({ source: "escape" });
      return;
    }

    if (event.key === "Tab") {
      // Treat Tab as a dismiss (revert + close) for predictable state.
      this.cancel({ source: "outside" });
      return;
    }

    const items = this.#itemsInMenu(openMenu);
    if (items.length === 0) return;

    const currentIndex = items.indexOf(activeElement);

    switch (event.key) {
      case "ArrowDown": {
        event.preventDefault();
        const next = items[(currentIndex + 1 + items.length) % items.length];
        this.#setRovingFocus(next, items);
        break;
      }
      case "ArrowUp": {
        event.preventDefault();
        const next = items[(currentIndex - 1 + items.length) % items.length];
        this.#setRovingFocus(next, items);
        break;
      }
      case "Home": {
        event.preventDefault();
        this.#setRovingFocus(items[0], items);
        break;
      }
      case "End": {
        event.preventDefault();
        this.#setRovingFocus(items[items.length - 1], items);
        break;
      }
      case "ArrowRight": {
        const submenuMenuId = activeElement?.dataset?.submenuMenuId;
        if (submenuMenuId) {
          event.preventDefault();
          const submenuMenu = this.element.querySelector(
            `#${CSS.escape(submenuMenuId)}`,
          );
          if (submenuMenu) {
            this.#openSubmenu(activeElement, submenuMenu);
            this.#focusFirstItem(submenuMenu);
          }
        }
        break;
      }
      case "ArrowLeft": {
        if (openMenu !== this.#rootMenu()) {
          event.preventDefault();
          const labelledBy = openMenu.getAttribute("aria-labelledby");
          this.#closeSubmenu();
          if (labelledBy) {
            const parentTrigger = this.element.querySelector(
              `#${CSS.escape(labelledBy)}`,
            );
            parentTrigger?.focus();
          }
        }
        break;
      }
      case "Enter":
      case " ": {
        // Let the item-specific click handlers run.
        // (Clicking buttons triggers Stimulus actions already.)
        break;
      }
      default:
        break;
    }
  }

  #onDocumentPointerDown(event) {
    if (!this.#isRootMenuOpen()) return;

    const target = event.target;
    if (!target) return;

    if (this.element.contains(target)) {
      return;
    }

    this.cancel({ source: "outside" });
  }

  #openSubmenu(trigger, submenuMenu) {
    this.cancelScheduledSubmenuClose();

    if (this.#openSubmenuMenu && this.#openSubmenuMenu !== submenuMenu) {
      this.#closeSubmenu();
    }

    this.#openSubmenuMenu = submenuMenu;

    submenuMenu.hidden = false;
    submenuMenu.dataset.state = "open";

    trigger.setAttribute("aria-expanded", "true");

    this.#positionSubmenu(trigger, submenuMenu);
  }

  #closeSubmenu() {
    if (!this.#openSubmenuMenu) return;

    const labelledBy = this.#openSubmenuMenu.getAttribute("aria-labelledby");
    const trigger = labelledBy
      ? this.element.querySelector(`#${CSS.escape(labelledBy)}`)
      : null;

    this.#openSubmenuMenu.hidden = true;
    this.#openSubmenuMenu.dataset.state = "closed";

    if (trigger) {
      trigger.setAttribute("aria-expanded", "false");
    }

    this.#openSubmenuMenu = null;

    if (this.#submenuCleanupAutoUpdate) {
      this.#submenuCleanupAutoUpdate();
      this.#submenuCleanupAutoUpdate = null;
    }
  }

  #captureSnapshot() {
    const inputs = this.inputTargets.map((input) => ({
      type: input.type,
      name: input.name,
      value: input.value,
      checked: Boolean(input.checked),
    }));

    return { inputs };
  }

  #revertToSnapshot() {
    if (!this.#snapshot?.inputs) return;

    this.#snapshot.inputs.forEach((snap) => {
      const input = this.inputTargets.find(
        (el) =>
          el.type === snap.type &&
          el.name === snap.name &&
          el.value === snap.value,
      );
      if (!input) return;

      input.checked = snap.checked;

      if (input.type === "checkbox") {
        const button = this.#findItemButton(
          snap.name,
          snap.value,
          "menuitemcheckbox",
        );
        if (button) {
          this.#syncCheckboxButton(button, snap.checked);
        }
      }

      if (input.type === "radio") {
        // We'll sync all radios by name below.
      }
    });

    const radioNames = new Set(
      this.inputTargets.filter((i) => i.type === "radio").map((i) => i.name),
    );

    radioNames.forEach((name) => this.#syncRadioButtons(name));
  }

  #findInput(name, value) {
    return this.inputTargets.find(
      (el) => el.name === name && el.value === value,
    );
  }

  #findItemButton(name, value, role) {
    return this.itemTargets.find(
      (el) =>
        el.dataset.name === name &&
        el.dataset.value === value &&
        el.getAttribute("role") === role,
    );
  }

  #syncCheckboxButton(button, checked) {
    button.setAttribute("aria-checked", String(checked));

    const indicator = button.querySelector("span");
    if (!indicator) return;

    indicator.classList.toggle("bg-primary-700", checked);
    indicator.classList.toggle("border-primary-700", checked);
    indicator.classList.toggle("text-white", checked);
  }

  #syncRadioButtons(name) {
    const inputs = this.inputTargets.filter(
      (el) => el.type === "radio" && el.name === name,
    );

    const selected = inputs.find((i) => i.checked);

    this.itemTargets
      .filter(
        (el) =>
          el.getAttribute("role") === "menuitemradio" &&
          el.dataset.name === name,
      )
      .forEach((button) => {
        const isChecked = selected?.value === button.dataset.value;
        button.setAttribute("aria-checked", String(isChecked));

        const indicator = button.querySelector("span");
        if (!indicator) return;

        indicator.classList.toggle("bg-primary-700", isChecked);
        indicator.classList.toggle("border-primary-700", isChecked);
      });
  }

  #checkedCheckboxValues(preferredName = null) {
    const checkboxInputs = this.inputTargets.filter(
      (i) => i.type === "checkbox",
    );

    const valuesByName = checkboxInputs.reduce((memo, input) => {
      if (!memo[input.name]) memo[input.name] = [];
      if (input.checked) memo[input.name].push(input.value);
      return memo;
    }, {});

    const names = Object.keys(valuesByName);
    const name = preferredName || (names.length === 1 ? names[0] : null);
    const values = name ? valuesByName[name] || [] : [];

    return { name, values, valuesByName };
  }

  #requestSubmitNearestForm() {
    const form = this.element.closest("form");
    if (!form) return;

    if (typeof form.requestSubmit === "function") {
      form.requestSubmit();
      return;
    }

    // Fallback for older browsers
    form.submit();
  }
}
